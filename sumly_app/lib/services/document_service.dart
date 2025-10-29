import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'auth_service.dart';
import 'api_config.dart';

class DocumentService {
  final AuthService _authService = AuthService();

  // Subir documento compatible con Web y Mobile
  Future<Map<String, dynamic>> uploadDocument({
    PlatformFile? platformFile, // ✅ Cambiado de File a PlatformFile
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
      if (platformFile != null) {
        // ✅ Usar bytes del archivo (compatible con web y mobile)
        if (platformFile.bytes != null) {
          // Para Web - usa bytes directamente
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            platformFile.bytes!,
            filename: platformFile.name,
          );
          request.files.add(multipartFile);
        } else if (platformFile.path != null) {
          // Para Mobile - usa path
          final multipartFile = await http.MultipartFile.fromPath(
            'file',
            platformFile.path!,
            filename: platformFile.name,
          );
          request.files.add(multipartFile);
        } else {
          return {'success': false, 'message': 'No se pudo leer el archivo'};
        }
      } else if (text != null) {
        request.fields['text'] = text;
      } else {
        return {
          'success': false,
          'message': 'Debe proporcionar un archivo o texto',
        };
      }

      // Enviar request
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al subir documento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
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
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documentos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
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

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.documents}/$documentId',
      );
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener documento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
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

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.documents}/$documentId',
      );
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al eliminar documento',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
}
