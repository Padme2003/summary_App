import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class DocumentService {
  final AuthService _authService = AuthService();

  // Get all documents
  Future<List<DocumentModel>> getDocuments({
    String? type,
    bool? favorite,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autenticado');

      String url = ApiConfig.documents;
      final queryParams = <String, String>{};

      if (type != null) queryParams['type'] = type;
      if (favorite != null) queryParams['favorite'] = favorite.toString();

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.receiveTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final documents = (data['documents'] as List)
            .map((doc) => DocumentModel.fromJson(doc))
            .toList();
        return documents;
      }

      return [];
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }

  // Get single document
  Future<DocumentModel?> getDocument(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No autenticado');

      final response = await http.get(
        Uri.parse('${ApiConfig.documents}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.receiveTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return DocumentModel.fromJson(data['document']);
      }

      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  // Upload document from file
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String type,
    String? title,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.documents}/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['type'] = type;
      if (title != null) request.fields['title'] = title;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'document': data['document'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al subir archivo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Upload text
  Future<Map<String, dynamic>> uploadText({
    required String text,
    required String type,
    required String title,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.documents}/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'title': title,
          'text': text,
        }),
      ).timeout(const Duration(minutes: 2));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'document': data['document'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al procesar texto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Update document
  Future<bool> updateDocument(String id, Map<String, dynamic> updates) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.documents}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      ).timeout(ApiConfig.connectTimeout);

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'];
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }

  // Delete document
  Future<bool> deleteDocument(String id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.documents}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'];
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    return updateDocument(id, {'isFavorite': !isFavorite});
  }

  // Update playback position
  Future<bool> updatePlaybackPosition(String id, int position) async {
    return updateDocument(id, {
      'playbackPosition': position,
      'lastPlayed': DateTime.now().toIso8601String(),
    });
  }

  // Update progress
  Future<bool> updateProgress(String id, double progress) async {
    return updateDocument(id, {'progress': progress});
  }
}
