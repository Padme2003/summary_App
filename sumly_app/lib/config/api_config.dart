class ApiConfig {
  // Cambiar según tu entorno
  // Para Android Emulator: 10.0.2.2
  // Para iOS Simulator: localhost
  // Para dispositivo real: tu IP local (192.168.x.x)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/me';
  static const String documents = '$baseUrl/documents';
  static const String summaries = '$baseUrl/summaries';
  static const String audiobooks = '$baseUrl/audiobooks';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
