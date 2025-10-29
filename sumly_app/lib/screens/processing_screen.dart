import 'package:flutter/material.dart';

class ProcessingScreen extends StatefulWidget {
  final String mode; // 'summary' o 'audiobook'

  const ProcessingScreen({super.key, required this.mode});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  String _currentStep = 'Extrayendo texto...';

  final List<Map<String, String>> _summarySteps = [
    {'text': 'Extrayendo texto del documento...', 'duration': '2'},
    {'text': 'Analizando contenido con IA...', 'duration': '3'},
    {'text': 'Generando resumen inteligente...', 'duration': '2'},
    {'text': 'Creando audio del resumen...', 'duration': '1'},
    {'text': '¡Listo! Preparando visualización...', 'duration': '1'},
  ];

  final List<Map<String, String>> _audiobookSteps = [
    {'text': 'Extrayendo texto del documento...', 'duration': '2'},
    {'text': 'Detectando estructura de capítulos...', 'duration': '2'},
    {
      'text': 'Generando audio completo (esto puede tomar un momento)...',
      'duration': '5',
    },
    {'text': 'Optimizando calidad de audio...', 'duration': '2'},
    {'text': '¡Listo! Preparando reproductor...', 'duration': '1'},
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
    final steps = widget.mode == 'summary' ? _summarySteps : _audiobookSteps;

    for (int i = 0; i < steps.length; i++) {
      if (!mounted) break;

      setState(() {
        _currentStep = steps[i]['text']!;
        _progress = (i + 1) / steps.length;
      });

      await Future.delayed(Duration(seconds: int.parse(steps[i]['duration']!)));
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        widget.mode == 'summary' ? '/summary' : '/audiobook',
      );
    }
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

              // Mensaje de espera
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
          ),
        ),
      ),
    );
  }
}
