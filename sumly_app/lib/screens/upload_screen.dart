import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/document_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final DocumentService _documentService = DocumentService();
  String? _selectedFileName;
  String? _selectedFilePath;
  int _selectedTab = 0; // 0 = Archivo, 1 = Texto
  int _selectedMode = 0; // 0 = Resumen, 1 = Audiolibro
  bool _isProcessing = false;
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
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
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

  Future<void> _processContent() async {
    if (_selectedTab == 0 && _selectedFilePath == null) {
      _showErrorSnackBar('Por favor selecciona un archivo');
      return;
    }

    if (_selectedTab == 1 && _textController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor ingresa texto para procesar');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final type = _selectedMode == 0 ? 'summary' : 'audiobook';

      final result = await _documentService.uploadDocument(
        file: _selectedFilePath != null ? File(_selectedFilePath!) : null,
        text: _selectedTab == 1 ? _textController.text.trim() : null,
        type: type,
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar a la pantalla de procesamiento con el documento ID
          Navigator.pushNamed(
            context,
            '/processing',
            arguments: {
              'mode': type,
              'documentId': result['data']['documentId'],
            },
          );
        } else {
          _showErrorSnackBar(result['message'] ?? 'Error al subir documento');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nuevo Contenido',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 24),
            _buildTabSelector(),
            const SizedBox(height: 24),
            if (_selectedTab == 0) _buildFileUploadSection(),
            if (_selectedTab == 1) _buildTextInputSection(),
            const SizedBox(height: 24),
            _buildProcessButton(),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: 'Resumen IA',
              icon: Icons.auto_awesome,
              subtitle: '5-15 min',
              isSelected: _selectedMode == 0,
              color: Colors.blue,
              onTap: () => setState(() => _selectedMode = 0),
            ),
          ),
          Expanded(
            child: _buildModeButton(
              label: 'Audiolibro',
              icon: Icons.headphones,
              subtitle: 'Audio completo',
              isSelected: _selectedMode == 1,
              color: Colors.purple,
              onTap: () => setState(() => _selectedMode = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? color : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? color.withOpacity(0.7)
                        : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Subir Archivo',
              icon: Icons.upload_file,
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Pegar Texto',
              icon: Icons.text_fields,
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedFileName != null
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Toca para seleccionar archivo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PDF, TXT, DOC, DOCX',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            'Máximo 50 MB • 800 páginas',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 50, color: Colors.green[600]),
          const SizedBox(height: 16),
          Text(
            'Archivo seleccionado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _selectedFileName!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.refresh),
            label: const Text('Cambiar archivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.edit_note, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Escribe o pega tu texto aquí',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Pega tu texto aquí...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (text) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${_textController.text.split(' ').where((word) => word.isNotEmpty).length} palabras',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    final canProcess =
        (_selectedTab == 0 && _selectedFilePath != null) ||
        (_selectedTab == 1 && _textController.text.trim().isNotEmpty);

    return ElevatedButton(
      onPressed: (canProcess && !_isProcessing) ? _processContent : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canProcess
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedMode == 0 ? Icons.auto_awesome : Icons.headphones,
                  color: canProcess ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMode == 0 ? 'Generar Resumen' : 'Crear Audiolibro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canProcess ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedMode == 0 ? Colors.blue[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedMode == 0 ? Colors.blue[100]! : Colors.purple[100]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _selectedMode == 0 ? Colors.blue[700] : Colors.purple[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedMode == 0
                      ? 'Resumen Inteligente con IA'
                      : 'Audiolibro Completo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedMode == 0
                        ? Colors.blue[900]
                        : Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMode == 0
                      ? 'Se generará un resumen de 3-5 páginas con los puntos clave (5-15 min de audio)'
                      : 'Se convertirá todo el contenido a audio navegable por capítulos (tiempo según longitud)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedMode == 0
                        ? Colors.blue[800]
                        : Colors.purple[800],
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
