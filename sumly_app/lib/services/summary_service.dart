import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class SummaryService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Generar resumen
  Future<Map<String, dynamic>> generateSummary(String documentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.summaries}/generate'),
        headers: headers,
        body: jsonEncode({'documentId': documentId}),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if ((response.statusCode == 202 || response.statusCode == 200) &&
          data['success'] == true) {
        return {
          'success': true,
          'summary': Summary.fromJson(data['data']['summary']),
          'message': data['message'] ?? 'Generación iniciada',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al generar resumen',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener resumen por ID
  Future<Map<String, dynamic>> getSummary(String summaryId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.summaries}/$summaryId'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'summary': Summary.fromJson(data['data']['summary']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener resumen',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener todos los resúmenes
  Future<Map<String, dynamic>> getSummaries({bool? isFavorite}) async {
    try {
      final headers = await _getHeaders();

      String url = ApiConfig.summaries;
      if (isFavorite != null) {
        url += '?isFavorite=$isFavorite';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final summaries = (data['data']['summaries'] as List)
            .map((s) => Summary.fromJson(s))
            .toList();

        return {
          'success': true,
          'summaries': summaries,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener resúmenes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Alternar favorito
  Future<Map<String, dynamic>> toggleFavorite(String summaryId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse(ApiConfig.toggleFavorite(summaryId)),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'summary': Summary.fromJson(data['data']['summary']),
          'message': data['message'] ?? 'Favorito actualizado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar favorito',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener favoritos
  Future<Map<String, dynamic>> getFavorites() async {
    return getSummaries(isFavorite: true);
  }
}
