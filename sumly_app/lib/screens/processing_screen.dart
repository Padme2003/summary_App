import 'package:flutter/material.dart';
import '../services/summary_service.dart';
import '../utils/app_colors.dart';

class ProcessingScreen extends StatefulWidget {
  final String documentId;
  final String mode;

  const ProcessingScreen({
    super.key,
    required this.documentId,
    this.mode = 'summary',
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
      if (mounted) {
        setState(() {
          _currentStep = _summarySteps[0];
          _progress = 0.2;
        });
      }

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
    int currentStepIndex = 1;
    int pollAttempts = 0;
    const maxAttempts = 60; // 3 minutos máximo (60 * 3 segundos)

    while (pollAttempts < maxAttempts) {
      if (!mounted) break;

      await Future.delayed(const Duration(seconds: 3));
      pollAttempts++;

      // Actualizar paso visual
      if (currentStepIndex < _summarySteps.length - 1 && mounted) {
        setState(() {
          _currentStep = _summarySteps[currentStepIndex];
          _progress = 0.2 + (0.6 * currentStepIndex / (_summarySteps.length - 2));
        });
        currentStepIndex++;
      }

      // Verificar estado en el backend
      try {
        final statusResult = await _summaryService.getSummary(_generatedId!);

        if (statusResult['success'] != true) {
          continue; // Reintentar
        }

        final summary = statusResult['summary'];
        final status = summary.status;

        if (status == 'completed') {
          // ¡Completado!
          if (mounted) {
            setState(() {
              _currentStep = _summarySteps.last;
              _progress = 1.0;
            });
          }

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/summary',
              arguments: {'id': _generatedId},
            );
          }
          break;
        } else if (status == 'error' || status == 'failed') {
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

  void _showError(String message) {
    if (mounted) {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        body: SafeArea(
          child: _buildProcessingContent(context, isDark),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    if (_progress >= 1.0 || _hasError) {
      return true; // Si ya terminó o hubo error, permitir salir sin confirmación
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Cancelar procesamiento?',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Si sales ahora, se cancelará la generación del resumen y deberás iniciarlo nuevamente.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Continuar esperando',
              style: TextStyle(color: isDark ? AppColors.gold : AppColors.brown),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar y salir'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildProcessingContent(BuildContext context, bool isDark) {
    return Padding(
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
                gradient: isDark ? AppColors.goldGradient : AppColors.brownGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Título
          Text(
            'Generando Resumen Inteligente',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  color: isDark ? AppColors.darkCard : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: MediaQuery.of(context).size.width * _progress - 64,
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.goldGradient : AppColors.brownGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.5),
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
              color: isDark ? AppColors.gold : AppColors.brown,
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
              color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.3),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.gold : AppColors.brown,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    _currentStep,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
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
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos usando IA para crear un resumen de calidad',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
