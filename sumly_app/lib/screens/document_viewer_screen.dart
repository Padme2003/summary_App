import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String title;
  final String content;
  final String fileType;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.content,
    required this.fileType,
  });

  IconData _getFileIcon() {
    switch (fileType.toLowerCase()) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (fileType.toLowerCase()) {
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
        return Colors.blueGrey;
    }
  }

  String _getFileTypeName() {
    switch (fileType.toLowerCase()) {
      case 'doc':
      case 'docx':
        return 'Word';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint';
      case 'xls':
      case 'xlsx':
        return 'Excel';
      case 'txt':
        return 'Texto';
      default:
        return 'Documento';
    }
  }

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contenido copiado al portapapeles'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileColor = _getFileColor();
    final fileIcon = _getFileIcon();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              fileIcon,
              color: fileColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            tooltip: 'Copiar contenido',
            onPressed: () => _copyContent(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: fileColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: fileColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Documento ${_getFileTypeName()}: Contenido extraído',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido del documento
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: content.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: AppColors.warning,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se pudo extraer el contenido del documento',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
