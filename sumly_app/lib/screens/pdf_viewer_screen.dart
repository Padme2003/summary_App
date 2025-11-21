import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../utils/app_colors.dart';
import '../config/api_config.dart';

class PdfViewerScreen extends StatefulWidget {
  final String documentTitle;
  final String? pdfUrl;
  final String? pdfPath;

  const PdfViewerScreen({
    super.key,
    required this.documentTitle,
    this.pdfUrl,
    this.pdfPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Construir URL completa del PDF
  String? get _fullPdfUrl {
    if (widget.pdfUrl == null) return null;

    // Si ya es URL completa, usarla directamente
    if (widget.pdfUrl!.startsWith('http://') || widget.pdfUrl!.startsWith('https://')) {
      return widget.pdfUrl;
    }

    // Si es URL relativa, construir URL completa
    String baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    String pdfPath = widget.pdfUrl!;
    if (!pdfPath.startsWith('/')) pdfPath = '/$pdfPath';

    return '$baseUrl$pdfPath';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentTitle,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Página $_currentPage de $_totalPages',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.zoom_in,
              color: isDark ? AppColors.gold : AppColors.brown,
            ),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
          ),
          IconButton(
            icon: Icon(
              Icons.zoom_out,
              color: isDark ? AppColors.gold : AppColors.brown,
            ),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 1) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_fullPdfUrl != null && _errorMessage == null)
            SfPdfViewer.network(
              _fullPdfUrl!,
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _isLoading = false;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = details.description;
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
            )
          else if (widget.pdfPath != null)
            SfPdfViewer.file(
              File(widget.pdfPath!),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _isLoading = false;
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
            )
          else if (_errorMessage != null || widget.pdfUrl == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo cargar el PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.pdfUrl != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'URL: ${widget.pdfUrl}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.gold : AppColors.brown,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _totalPages > 0
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.first_page,
                      color: _currentPage > 1
                          ? (isDark ? AppColors.gold : AppColors.brown)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    onPressed: _currentPage > 1
                        ? () {
                            _pdfViewerController.jumpToPage(1);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: _currentPage > 1
                          ? (isDark ? AppColors.gold : AppColors.brown)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    onPressed: _currentPage > 1
                        ? () {
                            _pdfViewerController.previousPage();
                          }
                        : null,
                  ),
                  Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _currentPage < _totalPages
                          ? (isDark ? AppColors.gold : AppColors.brown)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            _pdfViewerController.nextPage();
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.last_page,
                      color: _currentPage < _totalPages
                          ? (isDark ? AppColors.gold : AppColors.brown)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            _pdfViewerController.jumpToPage(_totalPages);
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
