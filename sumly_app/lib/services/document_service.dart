import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class DocumentService {
  final AuthService _authService = AuthService();

  // Subir documento
  Future<Map<String, dynamic>> uploadDocument({
    File? file,
    String? text,
    required String type, // 'summary' o 'audiobook'
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadDocument}');
      final request = http.MultipartRequest('POST', url);

      // Agregar headers
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar tipo
      request.fields['type'] = type;

      // Agregar archivo o texto
      if (file != null) {
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      } else if (text != null) {
        request.fields['text'] = text;
      } else {
        return {
          'success': false,
          'message': 'Debe proporcionar un archivo o texto'
        };
      }

      // Enviar request
      final streamedResponse =
          await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al subir documento'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // Obtener todos los documentos
  Future<Map<String, dynamic>> getDocuments() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documents}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documentos'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // Obtener un documento específico
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final url =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documents}/$documentId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documento'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // Eliminar documento
  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final url =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documents}/$documentId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al eliminar documento'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }
}
