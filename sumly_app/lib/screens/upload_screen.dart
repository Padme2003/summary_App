import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/document_service.dart';
import '../utils/app_colors.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isUploading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar archivo: $e');
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFilePath = null;
    });
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
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

  Color _getFileColor(String fileName, bool isDark) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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
        return isDark ? AppColors.gold : AppColors.brown;
    }
  }

  Future<void> _processContent() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('Por favor selecciona un archivo');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final file = File(_selectedFilePath!);
      final result = await _documentService.uploadFile(file, _selectedFileName!);

      if (mounted) {
        setState(() => _isUploading = false);

        if (result['success'] == true) {
          final documentId = result['document'].id;

          Navigator.pushNamed(
            context,
            '/processing',
            arguments: {
              'mode': 'summary',
              'documentId': documentId,
            },
          );
        } else {
          _showErrorSnackBar(result['message'] ?? 'Error al subir archivo');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo Documento',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileUploadSection(),
            const SizedBox(height: 32),
            _buildProcessButton(),
            const SizedBox(height: 20),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedFileName != null
                    ? (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.5)
                    : (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _selectedFileName == null
                ? _buildUploadPlaceholder()
                : _buildFilePreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: isDark ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Toca para seleccionar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PDF, Word, PowerPoint, Excel, TXT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Máx. 50 MB',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileColor = _getFileColor(_selectedFileName!, isDark);
    final fileIcon = _getFileIcon(_selectedFileName!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono del tipo de archivo con color específico
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: fileColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              fileIcon,
              size: 36,
              color: fileColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Archivo seleccionado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: fileColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fileIcon,
                  size: 20,
                  color: fileColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _selectedFileName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botones para cambiar o eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.refresh, color: fileColor, size: 18),
                label: Text(
                  'Cambiar',
                  style: TextStyle(
                    color: fileColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _clearFile,
                icon: Icon(Icons.close, color: AppColors.error, size: 18),
                label: Text(
                  'Eliminar',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canProcess = _selectedFilePath != null;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: canProcess
            ? LinearGradient(
                colors: [
                  isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                ],
              )
            : null,
        color: canProcess
            ? null
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(14),
        boxShadow: canProcess
            ? [
                BoxShadow(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: (canProcess && !_isUploading) ? _processContent : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: _isUploading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.black : AppColors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: canProcess
                        ? (isDark ? AppColors.black : AppColors.white)
                        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Generar Resumen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: canProcess
                          ? (isDark ? AppColors.black : AppColors.white)
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.darkAccent : AppColors.lightAccent,
                  isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              color: isDark ? AppColors.black : AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen con IA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumen completo + audio en minutos',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
