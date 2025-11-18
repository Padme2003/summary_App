import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/summary_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final DocumentService _documentService = DocumentService();
  final SummaryService _summaryService = SummaryService();

  User? _user;
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          setState(() {
            _user = userResult['user'];
            _documents = docsResult['documents'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = userResult['message'] ?? 'Error al cargar datos';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16),
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

    final totalDocs = _documents.length;
    final processedDocs =
        _documents.where((d) => d.status == 'completed' || d.status == 'processed').length;
    final pendingDocs =
        _documents.where((d) => d.status == 'processing' || d.status == 'pending').length;
    final recentDocs = _documents.take(5).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar con gradiente
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.name ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contenido principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas
                    const Text(
                      'Tus Estadísticas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            '$totalDocs',
                            'documentos',
                            Icons.description,
                            Colors.blue,
                            '/library',
                            null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Procesados',
                            '$processedDocs',
                            'completados',
                            Icons.check_circle,
                            Colors.green,
                            '/library',
                            {'filter': 'processed'},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pendientes',
                            '$pendingDocs',
                            'por procesar',
                            Icons.pending,
                            Colors.orange,
                            '/library',
                            {'filter': 'pending'},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Resúmenes',
                            '${_user?.stats['totalSummaries'] ?? 0}',
                            'generados',
                            Icons.auto_stories,
                            Colors.purple,
                            '/summaries',
                            null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Acciones rápidas
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Nuevo\nResumen',
                            Icons.auto_awesome,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/upload'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            'Nuevo\nAudiolibro',
                            Icons.headphones,
                            Colors.purple,
                            () => Navigator.pushNamed(context, '/upload'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Documentos recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Documentos Recientes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalDocs > 3)
                          TextButton(
                            onPressed: () {
                              // Cambiar al tab de biblioteca
                            },
                            child: const Text('Ver todos'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (recentDocs.isEmpty)
                      _buildEmptyState()
                    else
                      ...recentDocs.map((doc) => _buildDocumentCard(doc)),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String route,
    Map<String, dynamic>? arguments,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          route,
          arguments: arguments,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    Color getStatusColor() {
      switch (document.status) {
        case 'processed':
          return Colors.green;
        case 'processing':
          return Colors.orange;
        case 'failed':
          return Colors.red;
        default:
          return Colors.grey;
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
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        default:
          return Icons.text_snippet;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDocumentOptions(document),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getFileIcon(),
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
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
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(document.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tienes documentos aún',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza subiendo tu primer documento',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/upload'),
            icon: const Icon(Icons.add),
            label: const Text('Subir Documento'),
          ),
        ],
      ),
    );
  }

  void _showDocumentOptions(DocumentModel document) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.summarize, color: Colors.blue),
              title: const Text('Generar Resumen'),
              subtitle: const Text('Crear resumen con IA'),
              onTap: () {
                Navigator.pop(context);
                _generateSummary(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.headphones, color: Colors.purple),
              title: const Text('Generar Audiolibro'),
              subtitle: const Text('Convertir a audio con TTS'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/processing',
                  arguments: {
                    'mode': 'audiobook',
                    'documentId': document.id,
                  },
                );
              },
            ),
            if (document.fileType == 'pdf')
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Ver PDF'),
                subtitle: const Text('Abrir documento original'),
                onTap: () {
                  Navigator.pop(context);
                  _viewPDF(document);
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Compartir'),
              subtitle: const Text('Compartir documento'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              subtitle: const Text('Borrar documento'),
              onTap: () {
                Navigator.pop(context);
                _deleteDocument(document);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummary(DocumentModel document) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _summaryService.generateSummary(document.id);

    if (mounted) Navigator.pop(context); // Cerrar loading

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resumen generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar a la pantalla de resumen
        final summary = result['summary'];
        final summaryId = summary is Map ? summary['_id'] : summary.id;
        Navigator.pushNamed(
          context,
          '/summary',
          arguments: {'id': summaryId},
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al generar resumen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewPDF(DocumentModel document) async {
    // Get filePath from document
    final filePath = document.filePath;

    if (filePath == null || filePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo PDF no está disponible'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Build the PDF URL from the backend
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          '¿Eliminar documento?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${document.title}"?',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _documentService.deleteDocument(document.id);

      if (mounted) Navigator.pop(context); // Cerrar loading

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          // Recargar datos
          _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al eliminar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
