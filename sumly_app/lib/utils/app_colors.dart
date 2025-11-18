import 'package:flutter/material.dart';

/// Paleta de colores y gradientes de la aplicación
class AppColors {
  // Colores principales - Modo Claro
  static const Color primaryCyan = Color(0xFF00D4FF);
  static const Color primaryPurple = Color(0xFFB465DA);
  static const Color secondaryPink = Color(0xFFFF6B9D);
  static const Color secondaryOrange = Color(0xFFFFA726);

  // Colores principales - Modo Oscuro
  static const Color primaryCyanDark = Color(0xFF00E5FF);
  static const Color primaryPurpleDark = Color(0xFFD946EF);
  static const Color secondaryPinkDark = Color(0xFFFF6BBF);
  static const Color secondaryOrangeDark = Color(0xFFFFB74D);

  // Colores de estado
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF60A5FA);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E2738);

  // Text colors
  static const Color textLight = Color(0xFF1A1F2E);
  static const Color textDark = Colors.white;
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  /// Gradiente principal (Cyan → Purple)
  static LinearGradient primaryGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [primaryCyanDark, primaryPurpleDark]
          : [primaryCyan, primaryPurple],
    );
  }

  /// Gradiente secundario (Pink → Orange)
  static LinearGradient secondaryGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [secondaryPinkDark, secondaryOrangeDark]
          : [secondaryPink, secondaryOrange],
    );
  }

  /// Gradiente de éxito (Verde)
  static LinearGradient successGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [successDark, const Color(0xFF6EE7B7)]
          : [successLight, successDark],
    );
  }

  /// Gradiente de advertencia (Ámbar)
  static LinearGradient warningGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [warningDark, const Color(0xFFFDE68A)]
          : [warningLight, warningDark],
    );
  }

  /// Gradiente de error (Rojo)
  static LinearGradient errorGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [errorDark, const Color(0xFFFECACA)]
          : [errorLight, errorDark],
    );
  }

  /// Gradiente de info (Azul)
  static LinearGradient infoGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [infoDark, const Color(0xFF93C5FD)]
          : [infoLight, infoDark],
    );
  }

  /// Gradiente de fondo sutil
  static LinearGradient backgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              backgroundDark,
              const Color(0xFF1A1F2E),
              const Color(0xFF16213E),
            ]
          : [
              backgroundLight,
              const Color(0xFFE8EAF6),
              const Color(0xFFDCE4F7),
            ],
    );
  }

  /// Sombra de card con color
  static List<BoxShadow> cardShadow(bool isDark, {Color? color}) {
    return [
      BoxShadow(
        color: (color ?? primaryCyan).withOpacity(isDark ? 0.2 : 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -5,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Sombra para botones elevados
  static List<BoxShadow> buttonShadow(bool isDark) {
    return [
      BoxShadow(
        color: primaryCyan.withOpacity(isDark ? 0.4 : 0.3),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Obtener color por categoría
  static Color getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'resumen':
      case 'summary':
        return isDark ? infoLight : infoLight;
      case 'audiolibro':
      case 'audiobook':
        return isDark ? primaryPurpleDark : primaryPurple;
      case 'documento':
      case 'document':
        return isDark ? secondaryPinkDark : secondaryPink;
      default:
        return isDark ? textSecondaryDark : textSecondaryLight;
    }
  }

  /// Obtener color de estado
  static Color getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'processed':
      case 'success':
        return isDark ? successDark : successLight;
      case 'processing':
      case 'pending':
        return isDark ? warningDark : warningLight;
      case 'failed':
      case 'error':
        return isDark ? errorDark : errorLight;
      default:
        return isDark ? textSecondaryDark : textSecondaryLight;
    }
  }

  /// Degradado de shimmer para efectos de carga
  static LinearGradient shimmerGradient(bool isDark) {
    final baseColor = isDark ? surfaceDark : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF2A3346) : const Color(0xFFF5F5F5);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.centerRight,
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}
