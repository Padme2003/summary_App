import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/animated_widgets.dart';
import '../services/summary_service.dart';
import '../services/document_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';

class SummaryScreen extends StatefulWidget {
  final String? summaryId;

  const SummaryScreen({super.key, this.summaryId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SummaryService _summaryService = SummaryService();
  final DocumentService _documentService = DocumentService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Summary? _summary;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  double _playbackSpeed = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
          setState(() => _isFavorite = !_isFavorite);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al actualizar favorito'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
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
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 28, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation(context);
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
          AnimatedHeartIcon(
            isFavorite: _isFavorite,
            onTap: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: _shareSummary,
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
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
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Volver atrás?',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El resumen se ha guardado en tu biblioteca.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Seguir leyendo',
              style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              foregroundColor: isDark ? AppColors.black : AppColors.white,
            ),
            child: const Text('Volver a biblioteca'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // HEADER COMPLETAMENTE REDISEÑADO
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final durationText = _summary?.audioDuration != null
        ? '${(_summary!.audioDuration! / 60).floor()} min'
        : 'Sin audio';

    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Card de icono de libro
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.darkAccent,
                      AppColors.darkAccent2,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.lightAccent,
                      AppColors.lightAccent2,
                    ],
                  ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 28,
              color: isDark ? AppColors.black : AppColors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            _summary?.title ?? 'Resumen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generado el ${_formatDate(_summary?.createdAt)}',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Tags REDISEÑADOS con más estilo
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildTag(
                'Resumen IA',
                [isDark ? AppColors.darkAccent : AppColors.lightAccent,
                 isDark ? AppColors.darkAccent2 : AppColors.lightAccent2],
              ),
              _buildTag(
                durationText,
                [AppColors.warning, AppColors.warning.withOpacity(0.7)],
              ),
              if (_summary?.keyPoints.isNotEmpty ?? false)
                _buildTag(
                  '${_summary!.keyPoints.length} puntos',
                  [AppColors.success, AppColors.success.withOpacity(0.7)],
                ),
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

  // TAG REDISEÑADO con gradiente
  Widget _buildTag(String label, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // MÁS PADDING
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.2),
            gradientColors[1].withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24), // MÁS REDONDEADO
        border: Border.all(
          color: gradientColors[0].withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: gradientColors[0],
        ),
      ),
    );
  }

  // CONTENT CARD REDISEÑADA
  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryContent = _summary?.content ?? 'No hay contenido disponible';
    final keyPoints = _summary?.keyPoints ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Contenido con MEJOR TIPOGRAFÍA
            Text(
              summaryContent,
              style: TextStyle(
                fontSize: 16,
                height: 1.8, // MÁS ALTURA DE LÍNEA
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w400,
              ),
            ),

            if (keyPoints.isNotEmpty) ...[
              const SizedBox(height: 40), // MÁS ESPACIO

              // Título de puntos clave
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.15),
                      (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Puntos Clave',
                      style: TextStyle(
                        fontSize: 17, // Optimizado
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Puntos clave REDISEÑADOS
              ...keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 8, right: 16),
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
                                color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.7,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
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

  // AUDIO CONTROLS REDISEÑADOS
  Widget _buildAudioControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAudio = _summary?.audioUrl != null && _summary!.audioUrl!.isNotEmpty;

    if (!hasAudio) {
      return Container(
        padding: const EdgeInsets.all(20), // Optimizado
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              const SizedBox(width: 10),
              Text(
                'Audio no disponible',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20), // Optimizado
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: _duration.inSeconds > 0
                          ? _position.inSeconds / _duration.inSeconds
                          : 0.0,
                      activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      inactiveColor: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                      onChanged: (value) {
                        final newPosition = Duration(
                          seconds: (value * _duration.inSeconds).round(),
                        );
                        _audioPlayer.seek(newPosition);
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de velocidad REDISEÑADO
                AnimatedScaleButton(
                  onPressed: () {
                    _showSpeedDialog();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                          (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      ),
                    ),
                  ),
                ),

                // Botón -10s
                AnimatedScaleButton(
                  onPressed: () => _seekRelative(-10),
                  child: Icon(
                    Icons.replay_10_rounded,
                    size: 28,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),

                // Botón PLAY/PAUSE REDISEÑADO
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final isPlaying = playerState?.playing ?? false;

                    return AnimatedScaleButton(
                      onPressed: _togglePlayPause,
                      scaleValue: 0.9,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 28,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      ),
                    );
                  },
                ),

                // Botón +10s
                AnimatedScaleButton(
                  onPressed: () => _seekRelative(10),
                  child: Icon(
                    Icons.forward_10_rounded,
                    size: 28,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),

                // Botón de descarga REDISEÑADO
                AnimatedScaleButton(
                  onPressed: _downloadAudio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                          (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.download_rounded,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      size: 18,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Velocidad de reproducción',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return RadioListTile<double>(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar audio: $e'),
            backgroundColor: AppColors.error,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          '¿Eliminar resumen?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este resumen?\n\n'
          'Esta acción no se puede deshacer.',
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
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _summaryService.deleteSummary(_summary!.id);

      if (mounted) {
        Navigator.pop(context);

        if (result['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Resumen eliminado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al eliminar'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewOriginalPDF() async {
    if (_summary?.documentId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _documentService.getDocument(_summary!.documentId!);

      if (mounted) {
        Navigator.pop(context);

        if (result['success'] == true) {
          final document = result['document'] as DocumentModel;

          if (document.filePath != null && document.filePath!.isNotEmpty) {
            final pdfUrl = document.filePath!.startsWith('http')
                ? document.filePath!
                : '${ApiConfig.baseUrl.replaceAll('/api', '')}${document.filePath}';

            Navigator.pushNamed(
              context,
              '/pdf-viewer',
              arguments: {
                'url': pdfUrl,
                'title': document.title,
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('PDF no disponible'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al cargar documento'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            if (_summary?.documentId != null)
              ListTile(
                leading: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                title: Text(
                  'Ver PDF original',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewOriginalPDF();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.copy_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
              title: Text(
                'Copiar texto',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.download_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
              title: Text(
                'Descargar audio',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadAudio();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text(
                'Eliminar resumen',
                style: TextStyle(color: AppColors.error),
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
