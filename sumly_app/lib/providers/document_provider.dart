import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _documents = [];
  DocumentModel? _currentDocument;
  bool _isLoading = false;
  String? _error;

  List<DocumentModel> get documents => _documents;
  DocumentModel? get currentDocument => _currentDocument;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DocumentModel> get summaries =>
      _documents.where((doc) => doc.type == 'summary').toList();

  List<DocumentModel> get audiobooks =>
      _documents.where((doc) => doc.type == 'audiobook').toList();

  List<DocumentModel> get favorites =>
      _documents.where((doc) => doc.isFavorite).toList();

  // Load all documents
  Future<void> loadDocuments({String? type, bool? favorite}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _documentService.getDocuments(
        type: type,
        favorite: favorite,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando documentos';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load single document
  Future<void> loadDocument(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentDocument = await _documentService.getDocument(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando documento';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload file
  Future<bool> uploadFile({
    required File file,
    required String type,
    String? title,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _documentService.uploadFile(
        file: file,
        type: type,
        title: title,
      );

      if (result['success']) {
        // Reload documents
        await loadDocuments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error subiendo archivo';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload text
  Future<bool> uploadText({
    required String text,
    required String type,
    required String title,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _documentService.uploadText(
        text: text,
        type: type,
        title: title,
      );

      if (result['success']) {
        // Reload documents
        await loadDocuments();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error procesando texto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final success = await _documentService.toggleFavorite(id, isFavorite);

    if (success) {
      // Update local state
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index != -1) {
        _documents[index] = DocumentModel.fromJson({
          ..._documents[index].toJson(),
          'isFavorite': !isFavorite,
        });
        notifyListeners();
      }
    }
  }

  // Update playback position
  Future<void> updatePlaybackPosition(String id, int position) async {
    await _documentService.updatePlaybackPosition(id, position);
  }

  // Update progress
  Future<void> updateProgress(String id, double progress) async {
    await _documentService.updateProgress(id, progress);

    // Update local state
    final index = _documents.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      _documents[index] = DocumentModel.fromJson({
        ..._documents[index].toJson(),
        'progress': progress,
      });
      notifyListeners();
    }
  }

  // Delete document
  Future<bool> deleteDocument(String id) async {
    final success = await _documentService.deleteDocument(id);

    if (success) {
      _documents.removeWhere((doc) => doc.id == id);
      notifyListeners();
      return true;
    }

    return false;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set current document
  void setCurrentDocument(DocumentModel? document) {
    _currentDocument = document;
    notifyListeners();
  }
}
