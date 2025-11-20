import 'package:flutter/material.dart';

/// Paleta de colores premium: Negro, Dorado, Café, Blanco
class AppColors {
  // ========================================
  // COLORES PRINCIPALES
  // ========================================

  // Dorado Premium
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);

  // Negro Premium
  static const Color black = Color(0xFF0A0A0A);
  static const Color blackLight = Color(0xFF1A1A1A);
  static const Color blackMedium = Color(0xFF2A2A2A);

  // Café Premium
  static const Color brown = Color(0xFF6B4423);
  static const Color brownLight = Color(0xFF8B5A3C);
  static const Color brownDark = Color(0xFF4A2C1A);

  // Blanco/Crema
  static const Color white = Color(0xFFFFFDF7);
  static const Color cream = Color(0xFFFAF8F3);
  static const Color creamDark = Color(0xFFF5F3ED);

  // ========================================
  // MODO OSCURO
  // ========================================

  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2A2A2A);

  static const Color darkTextPrimary = Color(0xFFFFFDF7);
  static const Color darkTextSecondary = Color(0xFFD4AF37);
  static const Color darkTextTertiary = Color(0xFFB8B8B8);

  static const Color darkAccent = Color(0xFFD4AF37);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // ========================================
  // MODO CLARO
  // ========================================

  static const Color lightBackground = Color(0xFFFFFDF7);
  static const Color lightSurface = Color(0xFFFAF8F3);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF6B4423);
  static const Color lightTextTertiary = Color(0xFF666666);

  static const Color lightAccent = Color(0xFF6B4423);
  static const Color lightBorder = Color(0xFFE8E6E1);

  // ========================================
  // ESTADOS
  // ========================================

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = Color(0xFF0288D1);

  // ========================================
  // GRADIENTES
  // ========================================

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient brownGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brownLight, brown, brownDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blackLight, black],
  );

  // ========================================
  // OPACIDADES
  // ========================================

  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Gradient premium principal (dorado para dark, café para light)
  static LinearGradient primaryGradient(bool isDark) {
    return isDark ? goldGradient : brownGradient;
  }

  /// Shadow sutil para cards
  static List<BoxShadow> cardShadow(bool isDark, {Color? color}) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(isDark ? 0.2 : 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Surface color para dark mode
  static Color get surfaceDark => darkSurface;
}
