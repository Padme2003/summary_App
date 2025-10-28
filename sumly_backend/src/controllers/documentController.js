const Document = require('../models/Document');
const aiService = require('../services/aiService');
const pdfParse = require('pdf-parse');
const fs = require('fs').promises;
const path = require('path');

// @desc    Subir y procesar documento
// @route   POST /api/documents/upload
exports.uploadDocument = async (req, res) => {
  try {
    const { type, text } = req.body;

    if (!type || (type !== 'summary' && type !== 'audiobook')) {
      return res.status(400).json({
        success: false,
        message: 'Tipo de documento inválido',
      });
    }

    let content = '';
    let title = '';
    let fileName = null;
    let fileSize = null;

    // Si se subió un archivo
    if (req.file) {
      fileName = req.file.originalname;
      fileSize = req.file.size;
      title = fileName;

      // Extraer texto del archivo según el tipo
      const filePath = req.file.path;
      const fileExtension = path.extname(fileName).toLowerCase();

      if (fileExtension === '.pdf') {
        const dataBuffer = await fs.readFile(filePath);
        const data = await pdfParse(dataBuffer);
        content = data.text;
      } else if (fileExtension === '.txt') {
        content = await fs.readFile(filePath, 'utf-8');
      } else {
        return res.status(400).json({
          success: false,
          message: 'Tipo de archivo no soportado',
        });
      }

      // Eliminar archivo después de extraer el texto
      await fs.unlink(filePath);
    } else if (text) {
      // Si se proporcionó texto directamente
      content = text;
      title = 'Texto pegado - ' + new Date().toLocaleDateString();
    } else {
      return res.status(400).json({
        success: false,
        message: 'Debes proporcionar un archivo o texto',
      });
    }

    // Validar que hay contenido
    if (!content || content.trim().length < 50) {
      return res.status(400).json({
        success: false,
        message: 'El contenido es demasiado corto',
      });
    }

    // Crear documento en la base de datos
    const document = await Document.create({
      user: req.user._id,
      title,
      originalContent: content,
      type,
      status: 'processing',
      fileName,
      fileSize,
    });

    // Procesar el contenido en segundo plano (simulado aquí)
    processDocumentAsync(document._id, content, type);

    res.status(201).json({
      success: true,
      data: {
        documentId: document._id,
        title: document.title,
        type: document.type,
        status: document.status,
      },
    });
  } catch (error) {
    console.error('Error en uploadDocument:', error);
    res.status(500).json({
      success: false,
      message: 'Error al procesar el documento',
      error: error.message,
    });
  }
};

// Función async para procesar documento
async function processDocumentAsync(documentId, content, type) {
  try {
    let summary = null;

    if (type === 'summary') {
      // Generar resumen con IA
      summary = await aiService.generateSummary(content);
    } else if (type === 'audiobook') {
      // Para audiolibros, dividir en capítulos
      const chapters = await aiService.divideIntoChapters(content);
      summary = JSON.stringify(chapters);
    }

    // Actualizar documento con el resultado
    await Document.findByIdAndUpdate(documentId, {
      summary,
      status: 'completed',
    });

    console.log(`Documento ${documentId} procesado exitosamente`);
  } catch (error) {
    console.error('Error al procesar documento:', error);
    await Document.findByIdAndUpdate(documentId, {
      status: 'failed',
    });
  }
}

// @desc    Obtener todos los documentos del usuario
// @route   GET /api/documents
exports.getDocuments = async (req, res) => {
  try {
    const documents = await Document.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .select('-originalContent');

    res.status(200).json({
      success: true,
      count: documents.length,
      data: documents,
    });
  } catch (error) {
    console.error('Error en getDocuments:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener documentos',
      error: error.message,
    });
  }
};

// @desc    Obtener un documento específico
// @route   GET /api/documents/:id
exports.getDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Verificar que el documento pertenece al usuario
    if (document.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado',
      });
    }

    res.status(200).json({
      success: true,
      data: document,
    });
  } catch (error) {
    console.error('Error en getDocument:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener documento',
      error: error.message,
    });
  }
};

// @desc    Eliminar un documento
// @route   DELETE /api/documents/:id
exports.deleteDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Verificar que el documento pertenece al usuario
    if (document.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado',
      });
    }

    await document.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Documento eliminado',
    });
  } catch (error) {
    console.error('Error en deleteDocument:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar documento',
      error: error.message,
    });
  }
};
