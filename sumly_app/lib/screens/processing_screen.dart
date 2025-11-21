import 'package:flutter/material.dart';
import '../services/summary_service.dart';
import '../models/models.dart';
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

        // Obtener status - puede venir como Map o como objeto Summary
        String status;
        if (summary is Map) {
          status = summary['status'] ?? '';
        } else if (summary is Summary) {
          status = summary.status;
        } else {
          continue; // Skip si no es ninguno de los dos
        }

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
              width: 120,
              height: 120,
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
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 60,
                color: isDark ? AppColors.black : AppColors.white,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Título
          Text(
            'Generando Resumen Inteligente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Barra de progreso
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 10,
                    width: constraints.maxWidth * _progress,
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
                          color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Porcentaje
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
            ),
          ),

          const SizedBox(height: 32),

          // Paso actual
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    _currentStep,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Estamos usando IA para crear un resumen de calidad',
              style: TextStyle(
                fontSize: 14,
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
