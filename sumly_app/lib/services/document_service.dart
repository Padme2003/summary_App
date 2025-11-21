import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class DocumentService {
  final AuthService _authService = AuthService();

  // Obtener headers con token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Subir archivo (usa timeout largo)
  Future<Map<String, dynamic>> uploadFile(File file, String title) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.documents}/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(ApiConfig.generationTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'document': DocumentModel.fromJson(data['data']['document']),
          'message': 'Documento subido exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al subir documento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Subir texto
  Future<Map<String, dynamic>> uploadText(String title, String content) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConfig.documents}/text'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'document': DocumentModel.fromJson(data['data']['document']),
          'message': 'Texto guardado exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al guardar texto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener un documento por ID
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.documents}/$documentId'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'document': DocumentModel.fromJson(data['data']['document']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener documentos
  Future<Map<String, dynamic>> getDocuments() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(ApiConfig.documents),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final documents = (data['data']['documents'] as List)
            .map((doc) => DocumentModel.fromJson(doc))
            .toList();

        return {
          'success': true,
          'documents': documents,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documentos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Toggle favorito
  Future<Map<String, dynamic>> toggleFavorite(String documentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('${ApiConfig.documents}/$documentId/favorite'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Favorito actualizado',
          'document': DocumentModel.fromJson(data['data']['document']),
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

  // Eliminar documento
  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('${ApiConfig.documents}/$documentId'),
        headers: headers,
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Documento eliminado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al eliminar',
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
