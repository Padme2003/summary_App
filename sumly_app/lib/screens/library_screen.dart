import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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

class _LibraryScreenState extends State<LibraryScreen> {
  // Services
  final AuthService _authService = AuthService();
  final DocumentService _documentService = DocumentService();
  final SummaryService _summaryService = SummaryService();

  // State
  User? _user;
  List<DocumentModel> _documents = [];
  Map<String, List<Summary>> _documentSummaries = {};
  Set<String> _expandedDocuments = {};
  String _selectedFilter = 'all';
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('📱 LibraryScreen initState - Loading data...');
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

          // DEBUG: Log del usuario cargado
          debugPrint('👤 Usuario cargado desde API: ${_user?.name} (ID: ${_user?.id})');

          _documents = docsResult['documents'] ?? [];

          // Load summaries for each document
          for (final doc in _documents) {
            try {
              final summariesResult = await _summaryService.getSummariesByDocument(doc.id);
              if (summariesResult['success'] == true) {
                _documentSummaries[doc.id] = summariesResult['summaries'] ?? [];
              }
            } catch (e) {
              debugPrint('Error loading summaries for doc ${doc.id}: $e');
            }
          }

          setState(() {
            _isLoading = false;
          });
        } else {
          // Si el perfil falla, intentar cargar usuario guardado como fallback
          debugPrint('⚠️ Error al obtener perfil: ${userResult['message']}');

          final savedUser = await _authService.getSavedUser();
          debugPrint('👤 Usuario guardado (fallback): ${savedUser?.name} (ID: ${savedUser?.id})');

          if (savedUser != null && docsResult['success'] == true) {
            _user = savedUser;
            _documents = docsResult['documents'] ?? [];

            // Load summaries for each document
            for (final doc in _documents) {
              try {
                final summariesResult = await _summaryService.getSummariesByDocument(doc.id);
                if (summariesResult['success'] == true) {
                  _documentSummaries[doc.id] = summariesResult['summaries'] ?? [];
                }
              } catch (e) {
                debugPrint('Error loading summaries for doc ${doc.id}: $e');
              }
            }

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
            // App Bar con gradiente
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
                      colors: [
                        isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                      ],
                    ),
                  ),
                  child: SafeArea(
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
                              color: isDark ? AppColors.black.withOpacity(0.7) : AppColors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDisplayName(),
                            style: TextStyle(
                              fontSize: 22,
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
                ),
              ),
              actions: [
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
              ],
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
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
            '${_documents.where((doc) => doc.status == 'completed' && (_documentSummaries[doc.id]?.isNotEmpty ?? false)).length}',
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
      switch (document.fileType) {
        case 'pdf':
          return Icons.picture_as_pdf_rounded;
        case 'doc':
        case 'docx':
          return Icons.description_rounded;
        default:
          return Icons.text_snippet_rounded;
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
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedDocuments.remove(document.id);
                  } else {
                    _expandedDocuments.add(document.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono con gradiente
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                            (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getFileIcon(),
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

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

                    const SizedBox(width: 8),

                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            document.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: document.isFavorite
                                ? AppColors.error
                                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                            size: 22,
                          ),
                          onPressed: () => _toggleFavorite(document),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summaries list (when expanded)
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
              'No hay documentos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFilter == 'all'
                  ? 'Comienza subiendo tu primer documento'
                  : 'No hay documentos con este filtro',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
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
}
