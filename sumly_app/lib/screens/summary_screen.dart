import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/animated_widgets.dart';
import '../services/summary_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class SummaryScreen extends StatefulWidget {
  final String? summaryId;

  const SummaryScreen({super.key, this.summaryId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SummaryService _summaryService = SummaryService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Summary? _summary;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  double _playbackSpeed = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _textSize = 16.0; // Tamaño de texto por defecto

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final result = await _summaryService.getSummary(widget.summaryId!);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _summary = result['summary'];
            _isFavorite = _summary?.isFavorite ?? false;
            _isLoading = false;
          });

          // Cargar audio si está disponible
          if (_summary?.audioUrl != null && _summary!.audioUrl!.isNotEmpty) {
            final audioUrl = _summary!.audioUrl!.startsWith('http')
                ? _summary!.audioUrl!
                : '${ApiConfig.baseUrl.replaceAll('/api', '')}${_summary!.audioUrl}';

            try {
              await _audioPlayer.setUrl(audioUrl);
            } catch (e) {
              debugPrint('Error loading audio: $e');
            }
          }
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Error al cargar resumen';
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

  void _setupAudioPlayer() {
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration ?? Duration.zero);
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      // Auto-navegar cuando termine el audio
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _seekRelative(int seconds) async {
    final newPosition = _position + Duration(seconds: seconds);
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > _duration ? _duration : newPosition);
    await _audioPlayer.seek(clampedPosition);
  }

  Future<void> _changeSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }

  Future<void> _toggleFavorite() async {
    if (_summary == null) return;

    // Actualizar UI optimista
    setState(() => _isFavorite = !_isFavorite);

    try {
      final result = await _summaryService.toggleFavorite(_summary!.id);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _summary = result['summary'];
            _isFavorite = _summary!.isFavorite;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Favorito actualizado'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Revertir si falló
          setState(() => _isFavorite = !_isFavorite);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al actualizar favorito'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Revertir si hay error
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareSummary() {
    if (_summary == null) return;

    final shareText = '''
📚 Resumen: ${_summary!.title}

${_summary!.content}

${_summary!.keyPoints.isNotEmpty ? '\n🔑 Puntos Clave:\n${_summary!.keyPoints.map((p) => '• $p').join('\n')}' : ''}

---
Generado con Sumly - Resúmenes Inteligentes con IA
''';

    Share.share(
      shareText,
      subject: 'Resumen - ${_summary!.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadSummary();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          AnimatedHeartIcon(
            isFavorite: _isFavorite,
            onTap: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.share, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: _shareSummary,
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedCard(delay: 0, child: _buildHeader()),
          Expanded(child: AnimatedCard(delay: 100, child: _buildContent())),
          AnimatedCard(delay: 200, child: _buildAudioControls()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final durationText = _summary?.audioDuration != null
        ? '${(_summary!.audioDuration! / 60).floor()} min'
        : 'Sin audio';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[700]!, Colors.blue[900]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_stories, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _summary?.title ?? 'Resumen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Generado el ${_formatDate(_summary?.createdAt)}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildTag('Resumen IA', Colors.blue),
              _buildTag(durationText, Colors.orange),
              if (_summary?.keyPoints.isNotEmpty ?? false)
                _buildTag('${_summary!.keyPoints.length} puntos', Colors.purple),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final summaryContent = _summary?.content ?? 'No hay contenido disponible';
    final keyPoints = _summary?.keyPoints ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.text_fields,
                    size: 20,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  onPressed: () {
                    _showTextSizeDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summaryContent,
              style: TextStyle(
                fontSize: _textSize,
                height: 1.6,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            if (keyPoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Puntos Clave',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasAudio = _summary?.audioUrl != null && _summary!.audioUrl!.isNotEmpty;

    if (!hasAudio) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Audio no disponible',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _duration.inSeconds > 0
                        ? _position.inSeconds / _duration.inSeconds
                        : 0.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        seconds: (value * _duration.inSeconds).round(),
                      );
                      _audioPlayer.seek(newPosition);
                    },
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedScaleButton(
                  onPressed: () {
                    _showSpeedDialog();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                AnimatedScaleButton(
                  onPressed: () => _seekRelative(-10),
                  child: Icon(
                    Icons.replay_10,
                    size: 32,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState?.playing ?? false;

                    return AnimatedScaleButton(
                      onPressed: _togglePlayPause,
                      scaleValue: 0.9,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedScaleButton(
                  onPressed: () => _seekRelative(10),
                  child: Icon(
                    Icons.forward_10,
                    size: 32,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                AnimatedScaleButton(
                  onPressed: _downloadAudio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.download,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      onPressed: _downloadAudio,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final min = (seconds / 60).floor();
    final sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showSpeedDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Velocidad de reproducción',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return RadioListTile<double>(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              value: speed,
              groupValue: _playbackSpeed,
              onChanged: (value) {
                _changeSpeed(value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTextSizeDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sizes = {
      'Pequeño': 14.0,
      'Normal': 16.0,
      'Grande': 18.0,
      'Muy grande': 20.0,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Tamaño del texto',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes.entries.map((entry) {
            final isSelected = _textSize == entry.value;
            return ListTile(
              title: Text(
                entry.key,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: entry.value,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
              onTap: () {
                setState(() {
                  _textSize = entry.value;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _downloadAudio() async {
    if (_summary?.audioUrl == null || _summary!.audioUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio no disponible para descargar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final audioUrl = _summary!.audioUrl!.startsWith('http')
          ? _summary!.audioUrl!
          : '${ApiConfig.baseUrl.replaceAll('/api', '')}${_summary!.audioUrl}';

      final uri = Uri.parse(audioUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abriendo descarga de audio...'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'No se puede abrir el enlace';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar audio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard() async {
    if (_summary == null) return;

    final textToCopy = '''
${_summary!.title}

${_summary!.content}

${_summary!.keyPoints.isNotEmpty ? 'Puntos Clave:\n${_summary!.keyPoints.map((p) => '• $p').join('\n')}' : ''}
''';

    await Clipboard.setData(ClipboardData(text: textToCopy));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado al portapapeles'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSummary() async {
    if (_summary == null) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          '¿Eliminar resumen?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este resumen?\n\n'
          'Esta acción no se puede deshacer.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _summaryService.deleteSummary(_summary!.id);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result['success'] == true) {
          Navigator.pop(context); // Go back to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resumen eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
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

  void _showOptionsMenu() {
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
            ListTile(
              leading: Icon(
                Icons.copy,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              title: Text(
                'Copiar texto',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.download,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              title: Text(
                'Descargar audio',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de descarga próximamente'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar resumen',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteSummary();
              },
            ),
          ],
        ),
      ),
    );
  }
}
