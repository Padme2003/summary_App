const Document = require('../models/Document');
const pdfParse = require('pdf-parse');
const fs = require('fs').promises;
const path = require('path');

// Subir documento
exports.uploadDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No se proporcionó ningún archivo',
      });
    }

    const { title, category, tags } = req.body;

    // Extraer contenido del archivo
    let content = '';
    let pages = 0;
    const filePath = req.file.path;
    const fileType = path.extname(req.file.originalname).slice(1).toLowerCase();

    try {
      if (fileType === 'pdf') {
        const dataBuffer = await fs.readFile(filePath);
        const pdfData = await pdfParse(dataBuffer);
        content = pdfData.text;
        pages = pdfData.numpages;
      } else if (fileType === 'txt') {
        content = await fs.readFile(filePath, 'utf-8');
      }
    } catch (error) {
      console.error('Error al procesar archivo:', error);
    }

    const wordCount = content.split(/\s+/).filter(word => word.length > 0).length;

    // Crear documento
    const document = await Document.create({
      user: req.user._id,
      title: title || req.file.originalname,
      originalFileName: req.file.originalname,
      filePath: req.file.path,
      fileSize: req.file.size,
      fileType,
      content,
      metadata: {
        pages,
        wordCount,
        language: 'es',
      },
      category: category || 'general',
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      status: 'completed',
    });

    // Actualizar estadísticas del usuario
    req.user.stats.totalDocuments += 1;
    await req.user.save({ validateBeforeSave: false });

    res.status(201).json({
      success: true,
      message: 'Documento subido exitosamente',
      data: {
        document,
      },
    });
  } catch (error) {
    console.error('Error al subir documento:', error);
    res.status(500).json({
      success: false,
      message: 'Error al subir documento',
      error: error.message,
    });
  }
};

// Subir texto
exports.uploadText = async (req, res) => {
  try {
    const { title, content, category, tags } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Título y contenido son requeridos',
      });
    }

    const wordCount = content.split(/\s+/).filter(word => word.length > 0).length;

    const document = await Document.create({
      user: req.user._id,
      title,
      originalFileName: `${title}.txt`,
      fileType: 'text',
      content,
      metadata: {
        wordCount,
        language: 'es',
      },
      category: category || 'general',
      tags: tags || [],
      status: 'completed',
    });

    req.user.stats.totalDocuments += 1;
    await req.user.save({ validateBeforeSave: false });

    res.status(201).json({
      success: true,
      message: 'Texto guardado exitosamente',
      data: {
        document,
      },
    });
  } catch (error) {
    console.error('Error al guardar texto:', error);
    res.status(500).json({
      success: false,
      message: 'Error al guardar texto',
      error: error.message,
    });
  }
};

// Obtener todos los documentos del usuario
exports.getDocuments = async (req, res) => {
  try {
    const { category, isFavorite, search } = req.query;

    const filter = { user: req.user._id };

    if (category) filter.category = category;
    if (isFavorite) filter.isFavorite = isFavorite === 'true';
    if (search) {
      filter.$text = { $search: search };
    }

    const documents = await Document.find(filter)
      .populate('summary')
      .populate('audiobook')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: documents.length,
      data: {
        documents,
      },
    });
  } catch (error) {
    console.error('Error al obtener documentos:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener documentos',
      error: error.message,
    });
  }
};

// Obtener un documento por ID
exports.getDocument = async (req, res) => {
  try {
    const document = await Document.findOne({
      _id: req.params.id,
      user: req.user._id,
    }).populate('summary').populate('audiobook');

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        document,
      },
    });
  } catch (error) {
    console.error('Error al obtener documento:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener documento',
      error: error.message,
    });
  }
};

// Actualizar documento
exports.updateDocument = async (req, res) => {
  try {
    const allowedFields = ['title', 'category', 'tags', 'isFavorite'];
    const updates = {};

    Object.keys(req.body).forEach((key) => {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    const document = await Document.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      updates,
      { new: true, runValidators: true }
    );

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Documento actualizado exitosamente',
      data: {
        document,
      },
    });
  } catch (error) {
    console.error('Error al actualizar documento:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar documento',
      error: error.message,
    });
  }
};

// Eliminar documento
exports.deleteDocument = async (req, res) => {
  try {
    const document = await Document.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    // Eliminar archivo físico si existe
    if (document.filePath) {
      try {
        await fs.unlink(document.filePath);
      } catch (error) {
        console.error('Error al eliminar archivo:', error);
      }
    }

    await document.deleteOne();

    req.user.stats.totalDocuments = Math.max(0, req.user.stats.totalDocuments - 1);
    await req.user.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      message: 'Documento eliminado exitosamente',
    });
  } catch (error) {
    console.error('Error al eliminar documento:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar documento',
      error: error.message,
    });
  }
};
