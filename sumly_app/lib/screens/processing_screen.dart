import 'package:flutter/material.dart';
import '../services/summary_service.dart';
import '../services/audiobook_service.dart';

class ProcessingScreen extends StatefulWidget {
  final String mode; // 'summary' o 'audiobook'
  final String documentId;

  const ProcessingScreen({
    super.key,
    required this.mode,
    required this.documentId,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  String _currentStep = 'Iniciando procesamiento...';

  final SummaryService _summaryService = SummaryService();
  final AudiobookService _audiobookService = AudiobookService();

  String? _generatedId;
  bool _hasError = false;
  String _errorMessage = '';

  final List<String> _summarySteps = [
    'Extrayendo texto del documento...',
    'Analizando contenido con IA...',
    'Generando resumen inteligente...',
    'Creando audio del resumen...',
    '¡Listo! Preparando visualización...',
  ];

  final List<String> _audiobookSteps = [
    'Extrayendo texto del documento...',
    'Detectando estructura de capítulos...',
    'Generando audio completo...',
    'Optimizando calidad de audio...',
    '¡Listo! Preparando reproductor...',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startProcessing();
  }

  void _startProcessing() async {
    try {
      // MODO AUDIOLIBRO: Ir directo a TTS Nativo (sin usar backend/cuotas)
      if (widget.mode == 'audiobook') {
        // Simular proceso de preparación
        setState(() {
          _currentStep = 'Preparando audiolibro con voz nativa...';
          _progress = 0.3;
        });

        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          _currentStep = 'Optimizando para reproducción...';
          _progress = 0.7;
        });

        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          _currentStep = '¡Listo! Preparando reproductor...';
          _progress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navegar al reproductor con modo TTS nativo
          Navigator.pushReplacementNamed(
            context,
            '/audiobook',
            arguments: {
              'documentId': widget.documentId,
              'useTtsNative': true,
            },
          );
        }
        return;
      }

      // MODO RESUMEN: Usar backend como siempre
      setState(() {
        _currentStep = _summarySteps[0];
        _progress = 0.2;
      });

      final result = await _summaryService.generateSummary(widget.documentId);

      if (result['success'] != true) {
        _showError(result['message'] ?? 'Error al iniciar generación');
        return;
      }

      // Obtener el ID generado
      _generatedId = result['summary'].id;

      // Paso 2: Polling - verificar estado cada 3 segundos
      await _pollForCompletion();
    } catch (e) {
      _showError('Error de conexión: $e');
    }
  }

  Future<void> _pollForCompletion() async {
    final steps = widget.mode == 'summary' ? _summarySteps : _audiobookSteps;
    int currentStepIndex = 1;
    int pollAttempts = 0;
    const maxAttempts = 60; // 3 minutos máximo (60 * 3 segundos)

    while (pollAttempts < maxAttempts) {
      if (!mounted) break;

      await Future.delayed(const Duration(seconds: 3));
      pollAttempts++;

      // Actualizar paso visual
      if (currentStepIndex < steps.length - 1) {
        setState(() {
          _currentStep = steps[currentStepIndex];
          _progress = 0.2 + (0.6 * currentStepIndex / (steps.length - 2));
        });
        currentStepIndex++;
      }

      // Verificar estado en el backend
      Map<String, dynamic> statusResult;

      try {
        if (widget.mode == 'summary') {
          statusResult = await _summaryService.getSummary(_generatedId!);
        } else {
          statusResult = await _audiobookService.getAudiobook(_generatedId!);
        }

        if (statusResult['success'] != true) {
          continue; // Reintentar
        }

        final item = widget.mode == 'summary'
            ? statusResult['summary']
            : statusResult['audiobook'];
        final status = item.status;

        if (status == 'completed') {
          // ¡Completado!
          setState(() {
            _currentStep = steps.last;
            _progress = 1.0;
          });

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              widget.mode == 'summary' ? '/summary' : '/audiobook',
              arguments: {'id': _generatedId},
            );
          }
          break;
        } else if (status == 'failed') {
          _showError('La generación falló. Por favor, intenta nuevamente.');
          break;
        }
      } catch (e) {
        // Continuar intentando en caso de error de red temporal
        continue;
      }
    }

    if (pollAttempts >= maxAttempts && mounted) {
      _showError(
          'La generación está tomando más tiempo del esperado. Por favor, verifica tu biblioteca más tarde.');
    }
  }

  void _showQuotaExceededDialog(Map<String, dynamic> result) {
    final quota = result['quota'];
    final resetDate = quota?['resetDate'] != null
        ? DateTime.parse(quota['resetDate'])
        : null;
    final daysUntilReset =
        resetDate?.difference(DateTime.now()).inDays ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber, color: Colors.orange[700], size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cuota mensual alcanzada',
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
              result['message'] ?? 'Has alcanzado tu límite de audiolibros este mes',
              style: TextStyle(fontSize: 15, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cuota mensual',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Usados:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '${quota?['used'] ?? 0} / ${quota?['limit'] ?? 10}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Se renueva en:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        '$daysUntilReset días',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                      'Puedes usar la voz nativa del dispositivo (ilimitado y gratis)',
                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a pantalla anterior
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              // Navegar al reproductor con modo TTS nativo
              Navigator.pushReplacementNamed(
                context,
                '/audiobook',
                arguments: {
                  'documentId': widget.documentId,
                  'useTtsNative': true,
                },
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Usar voz nativa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSummary = widget.mode == 'summary';
    final primaryColor = isSummary ? Colors.blue[600]! : Colors.purple[600]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSummary
                ? [Colors.white, Colors.blue.shade50, Colors.indigo.shade50]
                : [Colors.white, Colors.purple.shade50, Colors.pink.shade50],
          ),
        ),
        child: SafeArea(
          child: _buildProcessingContent(context, isSummary, primaryColor),
        ),
      ),
    );
  }

  Widget _buildProcessingContent(
    BuildContext context,
    bool isSummary,
    Color primaryColor,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icono animado
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSummary
                          ? [Colors.blue[400]!, Colors.blue[700]!]
                          : [Colors.purple[400]!, Colors.purple[700]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSummary ? Icons.auto_awesome : Icons.headphones,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Título
              Text(
                isSummary
                    ? 'Generando Resumen Inteligente'
                    : 'Creando Audiolibro Completo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Barra de progreso
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 8,
                    width: MediaQuery.of(context).size.width * _progress - 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSummary
                            ? [Colors.blue[400]!, Colors.blue[600]!]
                            : [Colors.purple[400]!, Colors.purple[600]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Porcentaje
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Paso actual
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        _currentStep,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Mensaje de error o espera
              if (_hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Esto puede tomar unos momentos...',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  isSummary
                      ? 'Estamos usando IA para crear un resumen de calidad'
                      : 'Estamos convirtiendo todo el libro a audio',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
