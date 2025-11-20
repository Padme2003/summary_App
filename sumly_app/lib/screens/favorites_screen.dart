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
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: _loadFavorites,
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (_favoriteDocuments.isNotEmpty) ...[
            Text(
              'Documentos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._favoriteDocuments.map((doc) => _buildDocumentCard(doc, isDark)),
            const SizedBox(height: 24),
          ],

          if (_favoriteSummaries.isNotEmpty) ...[
            Text(
              'Resúmenes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._favoriteSummaries.map((summary) => _buildSummaryCard(summary, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document, bool isDark) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDocumentOptions(document, isDark);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      document.title,
                      style: TextStyle(
                        fontSize: 16,
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
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(document.createdAt),
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      document.fileType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.gold : AppColors.brown,
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
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Summary summary, bool isDark) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummaryScreen(summaryId: summary.id),
            ),
          ).then((_) => _loadFavorites());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.title,
                      style: TextStyle(
                        fontSize: 16,
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
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(summary.createdAt),
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const Spacer(),
                  if (summary.audioUrl != null) ...[
                    Icon(Icons.headphones, size: 14, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${(summary.audioDuration ?? 0) ~/ 60} min',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline,
              size: 80,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin favoritos aún',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Los resúmenes que marques como favoritos aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
