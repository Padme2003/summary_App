class ApiConfig {
  // Cambiar según tu entorno
  // Para Android Emulator: 10.0.2.2
  // Para iOS Simulator: localhost
  // Para dispositivo real: tu IP local (192.168.x.x)

  // IMPORTANTE: Para dispositivos físicos, cambia esto a tu IP local
  // Ejemplo: 'http://192.168.1.100:5000/api'
  // Para encontrar tu IP en Windows: abre PowerShell y ejecuta "ipconfig"
  static const String baseUrl = 'http://192.168.1.100:5000/api';  // CAMBIAR POR TU IP LOCAL

  // Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/me';
  static const String updateProfile = '$baseUrl/auth/update-profile';
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
