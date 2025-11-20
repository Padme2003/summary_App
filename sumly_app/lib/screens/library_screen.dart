import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
  final DocumentService _documentService = DocumentService();
  final SummaryService _summaryService = SummaryService();

  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _documentService.getDocuments();

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _documents = result['documents'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Error al cargar documentos';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: $e';
          _isLoading = false;
        });
      }
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Mi Biblioteca',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              size: 26,
            ),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: isDark
            ? LinearGradient(colors: [AppColors.darkAccent, AppColors.darkAccent2])
            : LinearGradient(colors: [AppColors.lightAccent, AppColors.lightAccent2]),
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
            _loadDocuments();
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
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 100,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes documentos aún',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza cargando tu primer documento',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24), // MÁS PADDING
      children: [
        // Estadísticas REDISEÑADAS - HORIZONTAL
        _buildStatCard(
          'Total Documentos',
          '${_documents.length}',
          'en tu biblioteca',
          Icons.description_rounded,
          [isDark ? AppColors.darkAccent : AppColors.lightAccent,
           isDark ? AppColors.darkAccent2 : AppColors.lightAccent2],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Procesados',
          '${_documents.where((d) => d.status == 'processed').length}',
          'listos para leer',
          Icons.check_circle_rounded,
          [AppColors.success, AppColors.success.withOpacity(0.7)],
        ),

        const SizedBox(height: 48), // MÁS SPACING

        // Título
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Documentos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                    (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${_documents.length} total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Lista de documentos REDISEÑADOS
        ..._documents.map((document) => _buildDocumentCard(document)),
        const SizedBox(height: 80),
      ],
    );
  }

  // STAT CARD HORIZONTAL (REDISEÑO REAL)
  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28), // MÁS PADDING
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24), // MÁS REDONDEADO
        border: Border.all(
          color: gradientColors[0].withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row( // LAYOUT HORIZONTAL
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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

  // DOCUMENT CARD REDISEÑADO
  Widget _buildDocumentCard(DocumentModel document) {
    final fileType = document.fileType?.toUpperCase() ?? 'TXT';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getStatusColor() {
      switch (document.status) {
        case 'processed':
          return AppColors.success;
        case 'processing':
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
          return 'Procesado';
        case 'processing':
          return 'Procesando...';
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
      margin: const EdgeInsets.only(bottom: 20), // MÁS SPACING
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24), // MÁS REDONDEADO
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showOptionsMenu(document),
          child: Padding(
            padding: const EdgeInsets.all(24), // MÁS PADDING
            child: Row(
              children: [
                // Icono con gradiente
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                        (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    getFileIcon(),
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: getStatusColor().withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              getStatusText(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fileType,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
                      Icons.chevron_right_rounded,
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

  void _showOptionsMenu(DocumentModel document) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  document.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              ListTile(
                leading: Icon(
                  Icons.summarize_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Generar Resumen',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _generateSummary(document);
                },
              ),
              if (document.fileType == 'pdf')
                ListTile(
                  leading: Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                  title: Text(
                    'Ver PDF',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _viewPDF(document);
                  },
                ),
              ListTile(
                leading: Icon(Icons.share_rounded, color: AppColors.success),
                title: Text(
                  'Compartir',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _shareDocument(document);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: AppColors.error),
                title: Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDocument(document);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateSummary(DocumentModel document) async {
    Navigator.pushNamed(
      context,
      '/processing',
      arguments: {
        'mode': 'summary',
        'documentId': document.id,
      },
    );
  }

  void _viewPDF(DocumentModel document) async {
    final filePath = document.filePath;

    if (filePath == null || filePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('El archivo PDF no está disponible'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    final pdfUrl = filePath.startsWith('http')
        ? filePath
        : filePath.startsWith('/')
            ? '$baseUrl$filePath'
            : '$baseUrl/$filePath';

    Navigator.pushNamed(
      context,
      '/pdf-viewer',
      arguments: {
        'documentTitle': document.title,
        'pdfUrl': pdfUrl,
      },
    );
  }

  Future<void> _shareDocument(DocumentModel document) async {
    try {
      final content = document.content ?? '';
      final excerpt = content.length > 300
          ? '${content.substring(0, 300)}...'
          : content;

      final shareText = '''
📄 ${document.title}

$excerpt

---
Compartido desde Sumly - Tu asistente de lectura inteligente
      '''.trim();

      await Share.share(
        shareText,
        subject: document.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          '¿Eliminar documento?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${document.title}"?\n\n'
          'Esta acción no se puede deshacer.',
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _documentService.deleteDocument(document.id);

      if (mounted) {
        Navigator.pop(context);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Documento eliminado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadDocuments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Error al eliminar el documento',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
