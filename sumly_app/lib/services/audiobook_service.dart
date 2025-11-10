import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class AudiobookService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener cuota de audiolibros
  Future<Map<String, dynamic>> getQuota() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.audiobooks}/quota'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'quota': data['data']['quota'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener cuota',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Generar audiolibro
  Future<Map<String, dynamic>> generateAudiobook(String documentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.audiobooks}/generate'),
        headers: headers,
        body: jsonEncode({'documentId': documentId}),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if ((response.statusCode == 202 || response.statusCode == 200) &&
          data['success'] == true) {
        return {
          'success': true,
          'audiobook': Audiobook.fromJson(data['data']['audiobook']),
          'quota': data['data']['quota'],
          'message': data['message'] ?? 'Generación iniciada',
        };
      } else if (response.statusCode == 403 && data['code'] == 'QUOTA_EXCEEDED') {
        return {
          'success': false,
          'quotaExceeded': true,
          'quota': data['data']?['quota'],
          'message': data['message'],
          'suggestion': data['data']?['suggestion'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al generar audiolibro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener audiolibro por ID
  Future<Map<String, dynamic>> getAudiobook(String audiobookId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.audiobooks}/$audiobookId'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'audiobook': Audiobook.fromJson(data['data']['audiobook']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener audiolibro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Actualizar posición de reproducción
  Future<Map<String, dynamic>> updatePosition(
    String audiobookId,
    int position,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('${ApiConfig.audiobooks}/$audiobookId/position'),
        headers: headers,
        body: jsonEncode({'position': position}),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar posición',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
