import 'package:flutter/foundation.dart';

class ApiConfig {
  // URL base dinámica según plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Para navegadores web (Chrome, Edge, Firefox, etc.)
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Para emulador Android (10.0.2.2 es el localhost del host)
      return 'http://10.0.2.2:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Para simulador iOS
      return 'http://localhost:3000/api';
    } else {
      // Fallback para otras plataformas (Windows, macOS, Linux)
      return 'http://localhost:3000/api';
    }
  }

  // Endpoints de autenticación
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Endpoints de documentos
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';

  // Timeout para todas las peticiones
  static const Duration timeout = Duration(seconds: 30);
}
