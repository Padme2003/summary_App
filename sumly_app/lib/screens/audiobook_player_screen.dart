import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/animated_widgets.dart';
import '../services/audiobook_service.dart';
import '../services/tts_service.dart';
import '../services/document_service.dart';
import '../models/models.dart';

class AudiobookPlayerScreen extends StatefulWidget {
  const AudiobookPlayerScreen({super.key});

  @override
  State<AudiobookPlayerScreen> createState() => _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends State<AudiobookPlayerScreen> {
  // Servicios
  final AudiobookService _audiobookService = AudiobookService();
  final TtsService _ttsService = TtsService();
  final DocumentService _documentService = DocumentService();

  // Estado de carga
  bool _isLoading = true;
  String? _errorMessage;

  // Datos
  Audiobook? _audiobook;
  DocumentModel? _document;
  bool _useTtsNative = false;
  Map<String, dynamic>? _quota;

  // Reproducción
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  double _progress = 0.0;
  bool _isFavorite = false;
  int _currentChapterIndex = 0;
  int _currentChapter = 1;
  bool _showChapters = false;

  // Duración total (en segundos)
  int _totalDuration = 300; // 5 minutos por defecto

  // Capítulos de ejemplo (para modo demo)
  final List<Map<String, dynamic>> _chapters = [
    {'num': 1, 'title': 'Introducción', 'duration': '5:30'},
    {'num': 2, 'title': 'Desarrollo', 'duration': '8:45'},
    {'num': 3, 'title': 'Conclusión', 'duration': '4:20'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Obtener argumentos de navegación
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        setState(() {
          _errorMessage = 'Error: No se proporcionaron datos';
          _isLoading = false;
        });
        return;
      }

      // Verificar si usa TTS nativo
      _useTtsNative = args['useTtsNative'] ?? false;

      if (_useTtsNative) {
        // Modo TTS nativo: cargar documento
        final documentId = args['documentId'];
        if (documentId == null) {
          setState(() {
            _errorMessage = 'Error: No se proporcionó ID del documento';
            _isLoading = false;
          });
          return;
        }

        final result = await _documentService.getDocument(documentId);
        if (result['success'] == true) {
          setState(() {
            _document = result['document'];
            _isFavorite = _document?.isFavorite ?? false;
            _isLoading = false;
          });

          // Inicializar TTS
          await _ttsService.initialize();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Error al cargar documento';
            _isLoading = false;
          });
        }
      } else {
        // Modo audiolibro: cargar audiolibro de Google Cloud TTS
        final audiobookId = args['id'];
        if (audiobookId == null) {
          setState(() {
            _errorMessage = 'Error: No se proporcionó ID del audiolibro';
            _isLoading = false;
          });
          return;
        }

        final result = await _audiobookService.getAudiobook(audiobookId);
        if (result['success'] == true) {
          setState(() {
            _audiobook = result['audiobook'];
            _isLoading = false;
          });

          // Obtener cuota
          _loadQuota();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Error al cargar audiolibro';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadQuota() async {
    final result = await _audiobookService.getQuota();
    if (result['success'] == true) {
      setState(() {
        _quota = result['quota'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[400]!),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildBookCover(),
                    const SizedBox(height: 24),
                    _buildBookInfo(),
                    const SizedBox(height: 32),
                    _buildProgressBar(),
                    const SizedBox(height: 32),
                    _buildMainControls(),
                    const SizedBox(height: 24),
                    _buildSecondaryControls(),
                    const SizedBox(height: 24),
                    if (_showChapters) _buildChaptersList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Indicador de modo TTS
          if (_useTtsNative)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[700]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[400]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_android, size: 14, color: Colors.green[200]),
                  const SizedBox(width: 4),
                  Text(
                    'Voz Nativa',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[100],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          // Indicador de cuota (solo para Google Cloud TTS)
          else if (_quota != null)
            GestureDetector(
              onTap: _showQuotaInfo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[700]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[400]!, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud, size: 14, color: Colors.blue[200]),
                    const SizedBox(width: 4),
                    Text(
                      '${_quota!['remaining']}/${_quota!['limit']} cuota',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[100],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          AnimatedHeartIcon(
            isFavorite: _isFavorite,
            onTap: _toggleFavorite,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover() {
    return Hero(
      tag: 'book-cover',
      child: Container(
        width: 200,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber[700]!, Colors.orange[800]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 60, color: Colors.white),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'CIEN AÑOS DE\nSOLEDAD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    final title = _useTtsNative
        ? (_document?.title ?? 'Documento')
        : (_audiobook?.title ?? 'Audiolibro');

    final chaptersCount = _useTtsNative ? 1 : (_audiobook?.chapters.length ?? 0);
    final duration = _useTtsNative ? 0 : (_audiobook?.duration ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _useTtsNative
                  ? Colors.green[400]?.withOpacity(0.3)
                  : Colors.purple[400]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _useTtsNative ? Colors.green[300]! : Colors.purple[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _useTtsNative ? Icons.phone_android : Icons.headphones,
                  size: 16,
                  color: _useTtsNative ? Colors.green[200] : Colors.purple[200],
                ),
                const SizedBox(width: 6),
                Text(
                  _useTtsNative ? 'Voz Nativa del Dispositivo' : 'Audiolibro Completo',
                  style: TextStyle(
                    fontSize: 12,
                    color: _useTtsNative ? Colors.green[100] : Colors.purple[100],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _useTtsNative
                ? 'Reproducción con TTS nativo'
                : 'Generado con Google Cloud TTS',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_useTtsNative && duration > 0)
                _buildInfoChip(_formatDuration(duration), Icons.schedule),
              if (!_useTtsNative && duration > 0) const SizedBox(width: 12),
              if (chaptersCount > 0)
                _buildInfoChip(
                  _useTtsNative
                      ? 'Documento completo'
                      : 'Cap ${_currentChapterIndex + 1}/$chaptersCount',
                  Icons.bookmark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[300],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final currentSeconds = (_progress * _totalDuration).toInt();
    final remainingSeconds = _totalDuration - currentSeconds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cap $_currentChapter',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _chapters[_currentChapter - 1]['title'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.purple[400],
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: Colors.purple[400]?.withOpacity(0.3),
            ),
            child: Slider(
              value: _progress,
              onChanged: (value) => setState(() => _progress = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentSeconds),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                Text(
                  '-${_formatDuration(remainingSeconds)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScaleButton(
            onPressed: () {
              if (_currentChapter > 1) {
                setState(() => _currentChapter--);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 20),
          AnimatedScaleButton(
            onPressed: () {
              setState(() {
                _progress = (_progress - 15 / _totalDuration).clamp(0.0, 1.0);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '-15',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          AnimatedScaleButton(
            onPressed: _togglePlayPause,
            scaleValue: 0.9,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple[400]!.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          AnimatedScaleButton(
            onPressed: () {
              setState(() {
                _progress = (_progress + 30 / _totalDuration).clamp(0.0, 1.0);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '+30',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          AnimatedScaleButton(
            onPressed: () {
              if (_currentChapter < _chapters.length) {
                setState(() => _currentChapter++);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.speed,
            label: '${_playbackSpeed}x',
            onTap: _showSpeedDialog,
          ),
          _buildControlButton(
            icon: Icons.nights_stay,
            label: 'Sleep',
            onTap: _showSleepTimerDialog,
          ),
          _buildControlButton(
            icon: Icons.bookmark_outline,
            label: 'Marcar',
            onTap: () {},
          ),
          _buildControlButton(
            icon: Icons.list,
            label: 'Capítulos',
            onTap: () => setState(() => _showChapters = !_showChapters),
            isActive: _showChapters,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return AnimatedScaleButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.purple[600]?.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.purple[400]!, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaptersList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Capítulos (${_chapters.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chapters.length,
            itemBuilder: (context, index) {
              final chapter = _chapters[index];
              final isActive = _currentChapter == chapter['num'];

              return AnimatedScaleButton(
                onPressed: () =>
                    setState(() => _currentChapter = chapter['num']),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.purple[600]?.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(color: Colors.purple[400]!, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${chapter['num']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.purple[600]
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter['title'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chapter['duration'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Reproduciendo',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Velocidad de reproducción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return RadioListTile<double>(
              title: Text('${speed}x'),
              value: speed,
              groupValue: _playbackSpeed,
              onChanged: (value) {
                setState(() => _playbackSpeed = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporizador de sueño'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                'Desactivado',
                '15 minutos',
                '30 minutos',
                '45 minutos',
                '1 hora',
                'Fin del capítulo',
              ].map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Temporizador: $option')),
                    );
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  Future<void> _shareDocument() async {
    if (_document == null) return;

    try {
      final title = _document!.title;
      final content = _document!.content ?? '';

      // Crear texto para compartir con extracto
      final excerpt = content.length > 300
          ? '${content.substring(0, 300)}...'
          : content;

      final shareText = '''
📖 $title

$excerpt

---
Compartido desde Sumly - Tu asistente de lectura inteligente
      '''.trim();

      await Share.share(
        shareText,
        subject: title,
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

  Future<void> _toggleFavorite() async {
    if (_document == null) return;

    // Cambiar estado optimistically
    setState(() => _isFavorite = !_isFavorite);

    final result = await _documentService.toggleFavorite(_document!.id);

    if (result['success'] == true) {
      // Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Favorito actualizado'),
          duration: const Duration(seconds: 1),
          backgroundColor: _isFavorite ? Colors.pink[600] : Colors.grey[700],
        ),
      );
    } else {
      // Revertir cambio si falló
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al actualizar favorito'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePlayPause() async {
    if (_useTtsNative) {
      // Modo TTS nativo
      if (_isPlaying) {
        await _ttsService.pause();
        setState(() => _isPlaying = false);
      } else {
        // Reproducir con TTS nativo
        if (_document?.content != null && _document!.content!.isNotEmpty) {
          await _ttsService.speak(_document!.content!);
          setState(() => _isPlaying = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay contenido para reproducir'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Modo audiolibro (Google Cloud TTS)
      // TODO: Implementar reproductor de audio para archivos MP3
      // Por ahora, solo cambiamos el estado
      setState(() => _isPlaying = !_isPlaying);

      if (_isPlaying) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reproductor de audio en desarrollo'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showQuotaInfo() {
    if (_quota == null) return;

    final resetDate = _quota!['resetDate'] != null
        ? DateTime.parse(_quota!['resetDate'])
        : null;
    final daysUntilReset = resetDate?.difference(DateTime.now()).inDays ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Cuota de Audiolibros', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Usados:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '${_quota!['used']} audiolibros',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Disponibles:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '${_quota!['remaining']} audiolibros',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Límite mensual:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '${_quota!['limit']} audiolibros',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Se renueva en:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '$daysUntilReset días',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Actualiza a Premium para audiolibros ilimitados',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDocumentInfo() {
    if (_document == null) return;

    final fileSize = _document!.fileSize != null
        ? '${(_document!.fileSize! / 1024).toStringAsFixed(2)} KB'
        : 'N/A';
    final wordCount = _document!.metadata?['wordCount'] ?? 0;
    final pages = _document!.metadata?['pages'] ?? 0;
    final createdAt = _document!.createdAt;
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, color: Colors.purple[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Información del Documento',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.title, 'Título', _document!.title),
              const Divider(height: 24),
              _buildInfoRow(Icons.insert_drive_file, 'Tipo',
                  _document!.fileType.toUpperCase()),
              const Divider(height: 24),
              _buildInfoRow(Icons.storage, 'Tamaño', fileSize),
              const Divider(height: 24),
              _buildInfoRow(Icons.text_fields, 'Palabras', '$wordCount palabras'),
              if (pages > 0) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.menu_book, 'Páginas', '$pages páginas'),
              ],
              const Divider(height: 24),
              _buildInfoRow(Icons.calendar_today, 'Fecha de creación', formattedDate),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.favorite,
                'Favorito',
                _document!.isFavorite ? 'Sí' : 'No',
                color: _document!.isFavorite ? Colors.pink : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? Colors.grey[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTtsNativeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_android, color: Colors.green[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Modo Voz Nativa',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estás usando la voz nativa de tu dispositivo',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.check_circle,
              'Ilimitado y gratis',
              'No hay límites de uso',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.offline_bolt,
              'Funciona sin conexión',
              'No requiere internet una vez cargado',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.speed,
              'Reproducción en tiempo real',
              'No requiere descargar archivos',
              Colors.orange,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes ajustar la velocidad de reproducción y más desde los controles',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    if (_document == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber, color: Colors.red[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Eliminar documento?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estás a punto de eliminar:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _document!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _deleteDocument();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument() async {
    if (_document == null) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _documentService.deleteDocument(_document!.id);

    // Cerrar indicador de carga
    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Documento eliminado'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al eliminar documento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2a3e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _useTtsNative ? Icons.phone_android : Icons.cloud_download,
                color: Colors.white,
              ),
              title: Text(
                _useTtsNative
                    ? 'Modo reproducción'
                    : 'Descargar audiolibro',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _useTtsNative
                    ? 'Voz nativa (sin descarga necesaria)'
                    : 'No disponible con TTS nativo',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                if (_useTtsNative) {
                  _showTtsNativeInfo();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text(
                'Información del documento',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDocumentInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar documento',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }
}
