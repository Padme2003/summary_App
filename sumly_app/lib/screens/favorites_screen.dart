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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummaryScreen(summaryId: summary.id),
            ),
          ).then((_) => _loadFavorites());
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
}
