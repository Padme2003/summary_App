import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/summary_service.dart';
import '../services/document_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';
import 'summary_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final SummaryService _summaryService = SummaryService();
  final DocumentService _documentService = DocumentService();

  List<Summary> _favoriteSummaries = [];
  List<DocumentModel> _favoriteDocuments = [];
  bool _isLoading = true;

  // Multi-select state
  bool _isMultiSelectMode = false;
  Set<String> _selectedSummaries = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final summariesResult = await _summaryService.getFavorites();
      final documentsResult = await _documentService.getDocuments();

      if (mounted) {
        setState(() {
          _favoriteSummaries = summariesResult['summaries'] ?? [];

          final allDocs = documentsResult['documents'] as List<DocumentModel>? ?? [];
          _favoriteDocuments = allDocs.where((doc) => doc.isFavorite).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFavorites = _favoriteDocuments.length + _favoriteSummaries.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Favoritos',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_favoriteSummaries.isNotEmpty)
            IconButton(
              icon: Icon(
                _isMultiSelectMode ? Icons.close : Icons.checklist_rounded,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = !_isMultiSelectMode;
                  if (!_isMultiSelectMode) {
                    _selectedSummaries.clear();
                  }
                });
              },
              tooltip: _isMultiSelectMode ? 'Cancelar' : 'Seleccionar',
            ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode && _selectedSummaries.isNotEmpty
          ? _buildDeleteButton(isDark)
          : null,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.gold : AppColors.brown,
              ),
            )
          : totalFavorites == 0
              ? _buildEmptyState(isDark)
              : _buildFavoritesList(isDark),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: isDark ? AppColors.gold : AppColors.brown,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          if (_favoriteDocuments.isNotEmpty) ...[
            Text(
              'Documentos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._favoriteDocuments.map((doc) => _buildDocumentCard(doc, isDark)),
            const SizedBox(height: 10),
          ],

          if (_favoriteSummaries.isNotEmpty) ...[
            Text(
              'Resúmenes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._favoriteSummaries.map((summary) => _buildSummaryCard(summary, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document, bool isDark) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDocumentOptions(document, isDark);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: isDark ? AppColors.black : AppColors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    color: AppColors.error,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(document.createdAt),
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      document.fileType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(DocumentModel document, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.summarize, color: isDark ? AppColors.gold : AppColors.brown),
              title: Text('Generar Resumen', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/processing',
                  arguments: {
                    'documentId': document.id,
                  },
                );
              },
            ),
            if (document.fileType == 'pdf')
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: AppColors.error),
                title: Text('Ver PDF', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _openPdfViewer(document);
                },
              ),
            ListTile(
              leading: Icon(Icons.favorite_border, color: AppColors.error),
              title: Text('Quitar de favoritos', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              onTap: () async {
                Navigator.pop(context);
                await _documentService.toggleFavorite(document.id);
                _loadFavorites();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Summary summary, bool isDark) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');
    final isSelected = _selectedSummaries.contains(summary.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: isSelected
          ? (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2)
          : (isDark ? AppColors.darkCard : AppColors.lightCard),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
              : (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isMultiSelectMode) {
            setState(() {
              if (isSelected) {
                _selectedSummaries.remove(summary.id);
              } else {
                _selectedSummaries.add(summary.id);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SummaryScreen(summaryId: summary.id),
              ),
            ).then((_) => _loadFavorites());
          }
        },
        onLongPress: () {
          if (!_isMultiSelectMode) {
            setState(() {
              _isMultiSelectMode = true;
              _selectedSummaries.add(summary.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isMultiSelectMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                            : Colors.grey,
                        size: 22,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? AppColors.darkAccent : AppColors.lightAccent,
                          isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: isDark ? AppColors.black : AppColors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isMultiSelectMode)
                    Icon(
                      Icons.favorite,
                      color: AppColors.error,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.content,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(summary.createdAt),
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const Spacer(),
                  if (summary.audioUrl != null) ...[
                    Icon(Icons.headphones, size: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${(summary.audioDuration ?? 0) ~/ 60} min',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPdfViewer(DocumentModel document) {
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    final filePath = document.filePath ?? '';

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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withOpacity(0.3),
                  AppColors.error.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_outline,
              size: 28,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin favoritos aún',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Los resúmenes que marques como favoritos aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(bool isDark) {
    final selectedCount = _selectedSummaries.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSummaries.length == _favoriteSummaries.length) {
                      _selectedSummaries.clear();
                    } else {
                      _selectedSummaries = _favoriteSummaries.map((s) => s.id).toSet();
                    }
                  });
                },
                icon: Icon(
                  _selectedSummaries.length == _favoriteSummaries.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 22,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                tooltip: _selectedSummaries.length == _favoriteSummaries.length
                    ? 'Deseleccionar'
                    : 'Seleccionar todos',
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: _deleteSelectedSummaries,
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Borrar', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
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

  Future<void> _deleteSelectedSummaries() async {
    final count = _selectedSummaries.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '¿Eliminar $count resumen${count > 1 ? 'es' : ''}?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            count == 1
                ? '¿Estás seguro de que deseas eliminar este resumen? Esta acción no se puede deshacer.'
                : '¿Estás seguro de que deseas eliminar estos $count resúmenes? Esta acción no se puede deshacer.',
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
        ),
      );

      int successCount = 0;
      int failCount = 0;

      for (String summaryId in _selectedSummaries) {
        final result = await _summaryService.deleteSummary(summaryId);
        if (result['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);

        setState(() {
          _selectedSummaries.clear();
          _isMultiSelectMode = false;
        });

        _loadFavorites();

        String message;
        Color backgroundColor;

        if (failCount == 0) {
          message = successCount == 1
              ? 'Resumen eliminado exitosamente'
              : '$successCount resúmenes eliminados exitosamente';
          backgroundColor = AppColors.success;
        } else if (successCount == 0) {
          message = 'Error al eliminar los resúmenes';
          backgroundColor = AppColors.error;
        } else {
          message = '$successCount eliminados, $failCount fallidos';
          backgroundColor = AppColors.warning;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
