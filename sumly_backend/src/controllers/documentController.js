const Document = require('../models/Document');
const pdfService = require('../services/pdfService');
const geminiService = require('../services/geminiService');
const ttsService = require('../services/ttsService');
const fs = require('fs').promises;

// @desc    Get all user documents
// @route   GET /api/documents
// @access  Private
exports.getDocuments = async (req, res) => {
  try {
    const { type, favorite } = req.query;

    const query = { user: req.user.id };

    if (type) query.type = type;
    if (favorite) query.isFavorite = favorite === 'true';

    const documents = await Document.find(query)
      .sort({ createdAt: -1 })
      .select('-originalText -processedText');

    res.status(200).json({
      success: true,
      count: documents.length,
      documents,
    });
  } catch (error) {
    console.error('Error obteniendo documentos:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener documentos',
      error: error.message,
    });
  }
};

// @desc    Get single document
// @route   GET /api/documents/:id
// @access  Private
exports.getDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Check ownership
    if (document.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado para acceder a este documento',
      });
    }

    res.status(200).json({
      success: true,
      document,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener documento',
      error: error.message,
    });
  }
};

// @desc    Upload and process document
// @route   POST /api/documents/upload
// @access  Private
exports.uploadDocument = async (req, res) => {
  try {
    const { type, title, text } = req.body;
    let extractedText = '';
    let documentTitle = title || 'Documento sin título';
    let documentAuthor = 'Desconocido';
    let fileName = null;
    let filePath = null;
    let fileSize = null;

    // Process file or text
    if (req.file) {
      fileName = req.file.originalname;
      filePath = req.file.path;
      fileSize = req.file.size;

      // Extract text from PDF
      const pdfData = await pdfService.extractText(filePath);
      extractedText = pdfData.text;

      // Get metadata
      const metadata = await pdfService.extractMetadata(filePath);
      if (!title) documentTitle = metadata.title;
      documentAuthor = metadata.author;
    } else if (text) {
      extractedText = text;
    } else {
      return res.status(400).json({
        success: false,
        message: 'Debes proporcionar un archivo o texto',
      });
    }

    if (!extractedText || extractedText.trim().length < 100) {
      return res.status(400).json({
        success: false,
        message: 'El texto extraído es demasiado corto (mínimo 100 caracteres)',
      });
    }

    // Create initial document
    const document = await Document.create({
      user: req.user.id,
      title: documentTitle,
      author: documentAuthor,
      type,
      originalText: extractedText,
      fileName,
      filePath,
      fileSize,
      status: 'processing',
    });

    // Process in background (return immediately)
    res.status(201).json({
      success: true,
      message: 'Documento recibido, procesando...',
      document: {
        id: document._id,
        title: document.title,
        type: document.type,
        status: document.status,
      },
    });

    // Process asynchronously
    processDocumentAsync(document._id, type, extractedText);

  } catch (error) {
    console.error('Error subiendo documento:', error);
    res.status(500).json({
      success: false,
      message: 'Error al procesar documento',
      error: error.message,
    });
  }
};

// Async processing function
async function processDocumentAsync(documentId, type, text) {
  try {
    const document = await Document.findById(documentId);

    if (type === 'summary') {
      // Generate summary
      const summaryResult = await geminiService.generateSummary(text);

      // Generate audio from summary
      const audioResult = await ttsService.generateAudio(summaryResult.summary);

      // Update document
      document.processedText = summaryResult.summary;
      document.audioUrl = audioResult.audioUrl;
      document.audioDuration = audioResult.duration;
      document.status = 'completed';
      document.progress = 1;

    } else if (type === 'audiobook') {
      // Generate chapters
      const chaptersResult = await geminiService.generateChapters(text);

      // Generate audiobook
      const audiobookResult = await ttsService.generateAudiobook(chaptersResult.chapters);

      // Update document
      document.processedText = text;
      document.audioUrl = audiobookResult.audioUrl;
      document.audioDuration = audiobookResult.totalDuration;
      document.chapters = audiobookResult.chapters;
      document.status = 'completed';
      document.progress = 1;
    }

    await document.save();
    console.log(`✅ Documento ${documentId} procesado exitosamente`);

  } catch (error) {
    console.error(`❌ Error procesando documento ${documentId}:`, error);

    const document = await Document.findById(documentId);
    if (document) {
      document.status = 'failed';
      await document.save();
    }
  }
}

// @desc    Update document
// @route   PUT /api/documents/:id
// @access  Private
exports.updateDocument = async (req, res) => {
  try {
    let document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Check ownership
    if (document.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado para modificar este documento',
      });
    }

    // Update allowed fields
    const allowedFields = ['isFavorite', 'progress', 'playbackPosition', 'lastPlayed'];
    const updates = {};

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    document = await Document.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    ).select('-originalText -processedText');

    res.status(200).json({
      success: true,
      document,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al actualizar documento',
      error: error.message,
    });
  }
};

// @desc    Delete document
// @route   DELETE /api/documents/:id
// @access  Private
exports.deleteDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Check ownership
    if (document.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado para eliminar este documento',
      });
    }

    // Delete file if exists
    if (document.filePath) {
      try {
        await fs.unlink(document.filePath);
      } catch (err) {
        console.error('Error eliminando archivo:', err);
      }
    }

    await document.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Documento eliminado exitosamente',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al eliminar documento',
      error: error.message,
    });
  }
};
