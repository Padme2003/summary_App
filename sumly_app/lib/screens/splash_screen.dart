import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Fade animation para el contenedor principal
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation para el logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Shimmer animation para el texto
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Esperar mínimo 1.5 segundos para mostrar el splash
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      _authService.isAuthenticated(),
    ]);

    if (!mounted) return;

    final isAuth = await _authService.isAuthenticated();

    Navigator.pushReplacementNamed(
      context,
      isAuth ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // Gradiente premium: gold a brown
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.blackLight, AppColors.brownDark]
                : [AppColors.cream, AppColors.creamDark],
            stops: const [0.0, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icono con escala animada
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppColors.gold, AppColors.goldLight]
                            : [AppColors.goldDark, AppColors.gold],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.brown.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 50,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Título animado con shimmer
                ShaderMask(
                  shaderCallback: (bounds) {
                    final shimmerOffset = _shimmerAnimation.value * 2 - 1;
                    return LinearGradient(
                      begin: Alignment(-1 - shimmerOffset, 0),
                      end: Alignment(1 - shimmerOffset, 0),
                      colors: isDark
                          ? [
                              AppColors.gold.withOpacity(0.3),
                              AppColors.gold,
                              AppColors.goldLight,
                              AppColors.gold,
                              AppColors.gold.withOpacity(0.3),
                            ]
                          : [
                              AppColors.brown.withOpacity(0.3),
                              AppColors.brown,
                              AppColors.goldDark,
                              AppColors.brown,
                              AppColors.brown.withOpacity(0.3),
                            ],
                      stops: const [0, 0.2, 0.5, 0.8, 1],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Sumly',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtítulo con opacidad animada
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    'Tu biblioteca de resúmenes',
                    style: TextStyle(
                      fontSize: 17,
                      color: isDark
                          ? AppColors.gold.withOpacity(0.8)
                          : AppColors.brown.withOpacity(0.7),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator animado
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.gold : AppColors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
