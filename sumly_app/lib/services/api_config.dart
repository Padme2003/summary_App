class ApiConfig {
  // Cambia esto a la URL de tu servidor backend
  // En desarrollo local: http://10.0.2.2:3000 (Android emulator)
  // o http://localhost:3000 (iOS simulator)
  // En producción: tu dominio real
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Endpoints
  static const String auth = '$baseUrl/auth';
  static const String documents = '$baseUrl/documents';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
