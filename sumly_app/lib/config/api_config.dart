class ApiConfig {
  // ========================================
  // CONFIGURACIÓN DE URL DEL BACKEND
  // ========================================

  // DESARROLLO LOCAL:
  // - Android Emulator: http://10.0.2.2:5000/api
  // - iOS Simulator: http://localhost:5000/api
  // - Dispositivo real: http://TU_IP_LOCAL:5000/api (ej: 192.168.18.54)

  // NGROK (para acceso desde cualquier red - datos móviles, WiFi diferente):
  // 1. Inicia ngrok: ngrok http 5000
  // 2. Copia la URL (ej: https://abc123.ngrok-free.app)
  // 3. Úsala aquí: https://abc123.ngrok-free.app/api

  // PRODUCCIÓN - RAILWAY (Backend en la nube 24/7):
  static const String baseUrl = 'https://summaryapp-production.up.railway.app/api';

  // DESARROLLO LOCAL (cuando necesites probar en local):
  // static const String baseUrl = 'http://192.168.18.54:5000/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/me';
  static const String updateProfile = '$baseUrl/auth/profile';
  static const String changePassword = '$baseUrl/auth/change-password';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';

  // Resource Endpoints
  static const String documents = '$baseUrl/documents';
  static const String summaries = '$baseUrl/summaries';
  static const String audiobooks = '$baseUrl/audiobooks';

  // Helper methods for dynamic endpoints
  static String toggleFavorite(String summaryId) => '$summaries/$summaryId/favorite';
  static String getSummary(String summaryId) => '$summaries/$summaryId';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
