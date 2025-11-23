import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/summary_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  // Services
  final AuthService _authService = AuthService();
  final DocumentService _documentService = DocumentService();
  final SummaryService _summaryService = SummaryService();

  // State
  User? _user;
  List<DocumentModel> _documents = [];
  Map<String, List<Summary>> _documentSummaries = {};
  Set<String> _expandedDocuments = {};
  Set<String> _selectedDocuments = {};
  String _selectedFilter = 'all';
  bool _isSearching = false;
  bool _isSelectionMode = false;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _decorativeIconController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('📱 LibraryScreen initState - Loading data...');

    // Inicializar animación del icono decorativo
    _decorativeIconController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _decorativeIconController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userResult = await _authService.getProfile();
      final docsResult = await _documentService.getDocuments();

      if (mounted) {
        if (userResult['success'] == true && docsResult['success'] == true) {
          _user = userResult['user'];
          debugPrint('👤 Usuario cargado desde API: ${_user?.name} (ID: ${_user?.id})');
          _documents = docsResult['documents'] ?? [];

          // ✅ NO cargar resúmenes aquí - se cargan al expandir
          setState(() {
            _isLoading = false;
          });
        } else {
          debugPrint('⚠️ Error al obtener perfil: ${userResult['message']}');
          final savedUser = await _authService.getSavedUser();
          debugPrint('👤 Usuario guardado (fallback): ${savedUser?.name} (ID: ${savedUser?.id})');

          if (savedUser != null && docsResult['success'] == true) {
            _user = savedUser;
            _documents = docsResult['documents'] ?? [];
            setState(() {
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = userResult['message'] ?? 'Error al cargar datos';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Excepción en _loadData: $e');
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Nueva función para cargar resúmenes solo cuando se expande
  Future<void> _loadSummariesForDocument(String documentId) async {
    if (_documentSummaries.containsKey(documentId)) return; // Ya cargados

    try {
      final summariesResult = await _summaryService.getSummariesByDocument(documentId);
      if (mounted && summariesResult['success'] == true) {
        setState(() {
          _documentSummaries[documentId] = summariesResult['summaries'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading summaries for doc $documentId: $e');
    }
  }

  List<DocumentModel> get _filteredDocuments {
    var filtered = _documents;

    // Apply filter
    switch (_selectedFilter) {
      case 'favorites':
        filtered = filtered.where((d) => d.isFavorite).toList();
        break;
      case 'recent':
        filtered = filtered.take(10).toList();
        break;
      case 'processing':
        filtered = filtered.where((d) => d.status == 'processing' || d.status == 'pending').toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) =>
        d.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  String _getDisplayName() {
    final displayName = _user?.name ?? 'Usuario';
    debugPrint('📝 Nombre mostrado: "$displayName" (user: ${_user?.name}, isEmpty: ${_user?.name?.isEmpty ?? true})');
    return displayName;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getFilterDescription() {
    switch (_selectedFilter) {
      case 'all':
        return 'Todos tus archivos subidos (PDF, Word, Excel, PowerPoint, TXT)';
      case 'favorites':
        return 'Documentos que marcaste como favoritos ⭐ para acceso rápido';
      case 'recent':
        return 'Los 10 documentos más recientes que subiste';
      case 'processing':
        return 'Documentos que están siendo procesados o pendientes';
      default:
        return 'Tus documentos';
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'all':
        return 'No hay documentos aún';
      case 'favorites':
        return 'No tienes favoritos';
      case 'recent':
        return 'No hay documentos recientes';
      case 'processing':
        return 'No hay documentos procesándose';
      default:
        return 'No hay documentos';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'all':
        return 'Sube tu primer archivo (PDF, Word, Excel, PowerPoint o TXT) y genera resúmenes inteligentes con IA';
      case 'favorites':
        return 'Toca el corazón ❤️ en cualquier documento para marcarlo como favorito y encontrarlo rápidamente aquí';
      case 'recent':
        return 'Tus documentos más recientes aparecerán aquí automáticamente cuando subas archivos';
      case 'processing':
        return 'Los documentos que estén siendo procesados aparecerán aquí temporalmente';
      default:
        return 'No hay documentos con este filtro';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Hoy';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        child: CustomScrollView(
          slivers: [
            // App Bar con gradiente premium
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.darkAccent.withOpacity(0.8),
                              AppColors.darkAccent2.withOpacity(0.6),
                            ]
                          : [
                              AppColors.lightAccent.withOpacity(0.9),
                              AppColors.lightAccent2.withOpacity(0.7),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Fondo gradiente animado con icono decorativo
                      Positioned(
                        right: -30,
                        top: -30,
                        child: RotationTransition(
                          turns: _decorativeIconController,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.gold.withOpacity(0.08)
                                  : AppColors.brown.withOpacity(0.08),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 100,
                              color: isDark
                                  ? AppColors.gold.withOpacity(0.1)
                                  : AppColors.brown.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                      // Contenido principal
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_getGreeting()},',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.black.withOpacity(0.75)
                                      : AppColors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getDisplayName(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.black : AppColors.white,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!_isSelectionMode)
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search_rounded,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _isSelectionMode ? Icons.close : Icons.delete_outline_rounded,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) {
                        _selectedDocuments.clear();
                      }
                    });
                  },
                ),
              ],
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? AppColors.darkAccent : AppColors.lightAccent,
              isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.pushNamed(context, '/upload');
            _loadData();
          },
          icon: Icon(Icons.add_rounded, color: isDark ? AppColors.black : AppColors.white),
          label: Text(
            'Nuevo Documento',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.black : AppColors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 44, color: AppColors.error),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field (if searching)
          if (_isSearching) ...[
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar documentos...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Estadísticas - 3 cards horizontales
          _buildStatCard(
            'Documentos',
            '${_documents.length}',
            'en tu biblioteca',
            Icons.description_rounded,
            [isDark ? AppColors.darkAccent : AppColors.lightAccent,
             isDark ? AppColors.darkAccent2 : AppColors.lightAccent2],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Procesados',
            '${_documents.where((doc) => doc.status == 'completed' || doc.status == 'processed').length}',
            'listos para leer',
            Icons.check_circle_rounded,
            [AppColors.success, AppColors.success.withOpacity(0.7)],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Pendientes',
            '${_documents.where((d) => d.status == 'processing' || d.status == 'pending').length}',
            'en procesamiento',
            Icons.pending_rounded,
            [AppColors.warning, AppColors.warning.withOpacity(0.7)],
          ),

          const SizedBox(height: 32),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all'),
                const SizedBox(width: 12),
                _buildFilterChip('Favoritos', 'favorites'),
                const SizedBox(width: 12),
                _buildFilterChip('Recientes', 'recent'),
                const SizedBox(width: 12),
                _buildFilterChip('Por Procesar', 'processing'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Título de documentos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Documentos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                          (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${_filteredDocuments.length} total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getFilterDescription(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de documentos
          if (_filteredDocuments.isEmpty)
            _buildEmptyState()
          else
            ..._filteredDocuments.map((document) => _buildDocumentCard(document)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                  ],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? AppColors.black : AppColors.white)
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    final fileType = document.fileType?.toUpperCase() ?? 'TXT';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedDocuments.contains(document.id);
    final summaries = _documentSummaries[document.id] ?? [];

    Color getStatusColor() {
      switch (document.status) {
        case 'processed':
        case 'completed':
          return AppColors.success;
        case 'processing':
        case 'pending':
          return AppColors.warning;
        case 'failed':
          return AppColors.error;
        default:
          return isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
      }
    }

    String getStatusText() {
      switch (document.status) {
        case 'processed':
        case 'completed':
          return 'Procesado';
        case 'processing':
          return 'Procesando...';
        case 'pending':
          return 'Pendiente';
        case 'failed':
          return 'Error';
        default:
          return 'Pendiente';
      }
    }

    IconData getFileIcon() {
      switch (document.fileType?.toLowerCase()) {
        case 'pdf':
          return Icons.picture_as_pdf_rounded;
        case 'doc':
        case 'docx':
          return Icons.description_rounded;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow_rounded;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart_rounded;
        case 'txt':
          return Icons.text_snippet_rounded;
        default:
          return Icons.insert_drive_file_rounded;
      }
    }

    Color getFileColor() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      switch (document.fileType?.toLowerCase()) {
        case 'pdf':
          return Colors.red;
        case 'doc':
        case 'docx':
          return Colors.blue;
        case 'ppt':
        case 'pptx':
          return Colors.orange;
        case 'xls':
        case 'xlsx':
          return Colors.green;
        case 'txt':
          return Colors.grey;
        default:
          return isDark ? AppColors.darkAccent : AppColors.lightAccent;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                if (_isSelectionMode) {
                  setState(() {
                    if (_selectedDocuments.contains(document.id)) {
                      _selectedDocuments.remove(document.id);
                    } else {
                      _selectedDocuments.add(document.id);
                    }
                  });
                } else {
                  if (isExpanded) {
                    setState(() {
                      _expandedDocuments.remove(document.id);
                    });
                  } else {
                    setState(() {
                      _expandedDocuments.add(document.id);
                    });
                    // Cargar resúmenes solo cuando se expande
                    await _loadSummariesForDocument(document.id);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Checkbox o icono
                    if (_isSelectionMode)
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10),
                        child: Checkbox(
                          value: _selectedDocuments.contains(document.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedDocuments.add(document.id);
                              } else {
                                _selectedDocuments.remove(document.id);
                              }
                            });
                          },
                          activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: getFileColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: getFileColor().withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          getFileIcon(),
                          color: getFileColor(),
                          size: 20,
                        ),
                      ),

                    // Información
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor().withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: getStatusColor().withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  getStatusText(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: getStatusColor(),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  fileType,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (summaries.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                                        (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${summaries.length} ${summaries.length == 1 ? 'resumen' : 'resúmenes'}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(document.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!_isSelectionMode) const SizedBox(width: 4),

                    // Botones de acción
                    if (!_isSelectionMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón para ver documento
                          IconButton(
                            icon: Icon(
                              getFileIcon(),
                              color: getFileColor(),
                              size: 20,
                            ),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _viewDocument(document),
                            tooltip: 'Ver ${fileType}',
                          ),
                          IconButton(
                            icon: Icon(
                              document.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: document.isFavorite
                                  ? AppColors.error
                                  : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                              size: 20,
                            ),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _toggleFavorite(document),
                            tooltip: document.isFavorite
                                ? 'Quitar de favoritos'
                                : 'Marcar como favorito para acceso rápido',
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            size: 22,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Summaries list (when expanded) - solo si no está en modo selección
          if (isExpanded && !_isSelectionMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            // Botón para ver resumen
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: ElevatedButton.icon(
                onPressed: () => _openDocument(document),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Ver Resumen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  foregroundColor: isDark ? AppColors.black : AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            _buildSummaryList(document.id),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryList(String documentId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaries = _documentSummaries[documentId] ?? [];

    if (summaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay resúmenes para este documento',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/processing',
                  arguments: {
                    'mode': 'summary',
                    'documentId': documentId,
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Generar Resumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/summary',
                arguments: {'id': summary.id},
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
                    (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(summary.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateTitle(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(DocumentModel document) async {
    try {
      final result = await _documentService.toggleFavorite(document.id);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            final index = _documents.indexWhere((d) => d.id == document.id);
            if (index != -1) {
              _documents[index] = result['document'];
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                document.isFavorite
                    ? 'Eliminado de favoritos'
                    : 'Agregado a favoritos',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(DocumentModel document) async {
    final fileType = document.fileType?.toLowerCase() ?? 'txt';

    // Para PDFs, usar el visor de PDF
    if (fileType == 'pdf') {
      if (document.filePath == null || document.filePath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF no disponible'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      try {
        // Construir URL correcta del PDF
        String fileUrl;
        if (document.filePath!.startsWith('http')) {
          fileUrl = document.filePath!;
        } else {
          // Remover /api del baseUrl y agregar el filePath
          final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
          // Asegurar que filePath comienza con /
          final path = document.filePath!.startsWith('/') ? document.filePath! : '/${document.filePath}';
          fileUrl = '$baseUrl$path';
        }

        debugPrint('📄 Abriendo PDF: $fileUrl');

        Navigator.pushNamed(
          context,
          '/pdf-viewer',
          arguments: {
            'url': fileUrl,
            'title': document.title,
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir PDF: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Para Word, Excel, PowerPoint - mostrar opciones
      _showDocumentOptionsDialog(document);
    }
  }

  Future<void> _showDocumentOptionsDialog(DocumentModel document) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileType = document.fileType?.toLowerCase() ?? 'txt';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Row(
          children: [
            Icon(
              _getIconForFileType(fileType),
              color: _getColorForFileType(fileType),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                document.title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Cómo deseas ver este documento?',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Opción 1: Ver texto extraído
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.text_snippet_rounded, color: Colors.blue, size: 20),
              ),
              title: const Text('Ver texto extraído'),
              subtitle: const Text('Contenido en texto plano'),
              onTap: () {
                Navigator.pop(context);
                _viewExtractedText(document);
              },
            ),
            const SizedBox(height: 8),
            // Opción 2: Abrir con...
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.open_in_new_rounded, color: Colors.orange, size: 20),
              ),
              title: const Text('Abrir con...'),
              subtitle: const Text('Usar app externa (Word, Excel, etc.)'),
              onTap: () {
                Navigator.pop(context);
                _downloadAndOpenFile(document);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFileType(String fileType) {
    switch (fileType) {
      case 'docx':
      case 'doc':
        return Icons.description_rounded;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Color _getColorForFileType(String fileType) {
    switch (fileType) {
      case 'docx':
      case 'doc':
        return Colors.blue;
      case 'xlsx':
      case 'xls':
        return Colors.green;
      case 'pptx':
      case 'ppt':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _viewExtractedText(DocumentModel document) async {
    final fileType = document.fileType?.toLowerCase() ?? 'txt';

    if (document.content == null || document.content!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El documento ${fileType.toUpperCase()} no tiene contenido disponible'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(document.title),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                document.content!,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadAndOpenFile(DocumentModel document) async {
    if (document.filePath == null || document.filePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo no disponible'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final fileType = document.fileType?.toLowerCase() ?? 'txt';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mostrar diálogo de descarga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
            ),
            const SizedBox(height: 20),
            Text(
              'Descargando ${fileType.toUpperCase()}...',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Construir URL correcta del archivo
      String fileUrl;
      if (document.filePath!.startsWith('http')) {
        fileUrl = document.filePath!;
      } else {
        // Remover /api del baseUrl y agregar el filePath
        final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
        // Asegurar que filePath comienza con /
        final path = document.filePath!.startsWith('/') ? document.filePath! : '/${document.filePath}';
        fileUrl = '$baseUrl$path';
      }

      debugPrint('📥 Descargando archivo desde: $fileUrl');

      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = '${document.id}.${fileType}';
      final filePath = '${tempDir.path}/$fileName';

      // Descargar archivo (sin token, ya que /uploads es público)
      final dio = Dio();
      await dio.download(fileUrl, filePath);

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de descarga

        // Abrir archivo con app externa
        final result = await OpenFilex.open(filePath);

        if (result.type != ResultType.done) {
          // Si no se pudo abrir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró una app para abrir archivos ${fileType.toUpperCase()}'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver texto',
                onPressed: () => _viewExtractedText(document),
                textColor: Colors.white,
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de descarga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar archivo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(DocumentModel document) async {
    // Intentar navegar a la pantalla de resúmenes directamente
    final summaries = _documentSummaries[document.id] ?? [];

    if (summaries.isNotEmpty) {
      // Si hay resúmenes, abrir el primero
      Navigator.pushNamed(
        context,
        '/summary',
        arguments: {'id': summaries[0].id},
      );
    } else {
      // Si no hay resúmenes, ofrecer generar uno
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay resúmenes para este documento'),
          action: SnackBarAction(
            label: 'Generar',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/processing',
                arguments: {
                  'mode': 'summary',
                  'documentId': document.id,
                },
              );
            },
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSelectionBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = _selectedDocuments.length;
    final filteredDocs = _filteredDocuments;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? 'Seleccionar'
                      : '$selectedCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_selectedDocuments.length == filteredDocs.length) {
                      _selectedDocuments.clear();
                    } else {
                      _selectedDocuments = filteredDocs.map((d) => d.id).toSet();
                    }
                  });
                },
                icon: Icon(
                  _selectedDocuments.length == filteredDocs.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 22,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                tooltip: _selectedDocuments.length == filteredDocs.length
                    ? 'Deseleccionar'
                    : 'Seleccionar todos',
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: selectedCount > 0 ? _deleteSelectedDocuments : null,
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Borrar', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedDocuments() async {
    final count = _selectedDocuments.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(
            '¿Eliminar $count documento${count > 1 ? 's' : ''}?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            count == 1
                ? '¿Estás seguro de que deseas eliminar este documento? Esta acción no se puede deshacer.'
                : '¿Estás seguro de que deseas eliminar estos $count documentos? Esta acción no se puede deshacer.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        int successCount = 0;
        for (final docId in _selectedDocuments) {
          final result = await _documentService.deleteDocument(docId);
          if (result['success'] == true) {
            successCount++;
          }
        }

        if (mounted) {
          Navigator.pop(context); // Cerrar loading

          if (successCount > 0) {
            setState(() {
              _documents.removeWhere((doc) => _selectedDocuments.contains(doc.id));
              _selectedDocuments.clear();
              _isSelectionMode = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$successCount documento${successCount > 1 ? 's' : ''} eliminado${successCount > 1 ? 's' : ''}'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            // Recargar datos para actualizar estadísticas
            _loadData();
          }

          if (successCount < count) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar algunos documentos'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
