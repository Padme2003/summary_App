class ApiConfig {
  // Cambiar esta URL según tu configuración
  // Para emulador Android: 10.0.2.2
  // Para dispositivo físico: tu IP local (ej: 192.168.1.x)
  // Para iOS simulator: localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Endpoints de autenticación
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Endpoints de documentos
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
