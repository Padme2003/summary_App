const Document = require('../models/Document');
const Summary = require('../models/Summary');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
const XLSX = require('xlsx');
const AdmZip = require('adm-zip');
const fs = require('fs').promises;
const fssync = require('fs');
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
        console.log('📄 Procesando PDF...');
        const dataBuffer = await fs.readFile(filePath);
        const pdfData = await pdfParse(dataBuffer);
        content = pdfData.text;
        pages = pdfData.numpages;
        console.log(`✓ PDF procesado: ${pages} páginas, ${content.length} caracteres`);
      } else if (fileType === 'txt') {
        console.log('📝 Procesando TXT...');
        content = await fs.readFile(filePath, 'utf-8');
        console.log(`✓ TXT procesado: ${content.length} caracteres`);
      } else if (fileType === 'docx' || fileType === 'doc') {
        console.log('📝 Procesando DOCX/DOC...');
        const dataBuffer = await fs.readFile(filePath);
        const result = await mammoth.extractRawText({ buffer: dataBuffer });
        content = result.value;
        // Estimar páginas (aproximadamente 500 palabras por página)
        const wordCount = content.split(/\s+/).filter(word => word.length > 0).length;
        pages = Math.ceil(wordCount / 500);
        console.log(`✓ DOCX procesado: ~${pages} páginas, ${content.length} caracteres`);
      } else if (fileType === 'pptx' || fileType === 'ppt') {
        console.log('📊 Procesando PPTX/PPT...');
        try {
          // Los archivos PPTX son ZIP que contienen XML
          const zip = new AdmZip(filePath);
          const zipEntries = zip.getEntries();
          let allText = [];

          // Extraer texto de los slides (archivos XML dentro de ppt/slides/)
          zipEntries.forEach(entry => {
            if (entry.entryName.match(/ppt\/slides\/slide\d+\.xml/)) {
              const xmlContent = entry.getData().toString('utf8');
              // Extraer texto entre tags <a:t>...</a:t>
              const textMatches = xmlContent.match(/<a:t[^>]*>([^<]*)<\/a:t>/g);
              if (textMatches) {
                textMatches.forEach(match => {
                  const text = match.replace(/<[^>]*>/g, '').trim();
                  if (text) allText.push(text);
                });
              }
            }
          });

          content = allText.join(' ');
          // Estimar slides (aproximadamente 150 palabras por slide)
          const wordCount = content.split(/\s+/).filter(word => word.length > 0).length;
          pages = Math.max(1, Math.ceil(wordCount / 150));
          console.log(`✓ PPTX procesado: ~${pages} slides, ${content.length} caracteres`);
        } catch (pptError) {
          console.error('❌ Error al procesar PowerPoint:', pptError);
          console.log('   Nota: Solo se soporta formato PPTX (no PPT antiguo)');
          content = '';
        }
      } else if (fileType === 'xlsx' || fileType === 'xls') {
        console.log('📊 Procesando XLSX/XLS...');
        const workbook = XLSX.readFile(filePath);
        let allText = [];

        // Extraer texto de todas las hojas
        workbook.SheetNames.forEach(sheetName => {
          const worksheet = workbook.Sheets[sheetName];
          const sheetData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

          // Convertir cada fila a texto
          sheetData.forEach(row => {
            const rowText = row.filter(cell => cell !== null && cell !== undefined).join(' ');
            if (rowText.trim()) {
              allText.push(rowText);
            }
          });
        });

        content = allText.join('\n');
        pages = workbook.SheetNames.length; // Número de hojas
        console.log(`✓ XLSX procesado: ${pages} hojas, ${content.length} caracteres`);
      } else {
        console.log(`⚠️  Tipo de archivo no soportado para extracción de texto: ${fileType}`);
        console.log('   El archivo se guardará pero sin contenido de texto.');
      }
    } catch (error) {
      console.error('❌ Error al procesar archivo:', error);
      content = ''; // Si falla, dejar contenido vacío pero continuar
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

// Toggle favorito
exports.toggleFavorite = async (req, res) => {
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

    document.isFavorite = !document.isFavorite;
    await document.save();

    res.status(200).json({
      success: true,
      message: document.isFavorite ? 'Agregado a favoritos' : 'Eliminado de favoritos',
      data: {
        document,
      },
    });
  } catch (error) {
    console.error('Error al actualizar favorito:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar favorito',
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

    // Eliminar archivo físico del documento si existe
    if (document.filePath) {
      try {
        await fs.unlink(document.filePath);
        console.log(`✓ Archivo del documento eliminado: ${document.filePath}`);
      } catch (error) {
        console.error('Error al eliminar archivo del documento:', error);
      }
    }

    // Buscar todos los resúmenes asociados a este documento
    const summaries = await Summary.find({ document: document._id });

    if (summaries.length > 0) {
      console.log(`📝 Encontrados ${summaries.length} resúmenes para eliminar`);

      // Eliminar archivos de audio de los resúmenes
      for (const summary of summaries) {
        if (summary.audioUrl) {
          try {
            // Construir ruta del archivo de audio
            const audioPath = summary.audioUrl.replace('/uploads/', './uploads/');
            if (fssync.existsSync(audioPath)) {
              await fs.unlink(audioPath);
              console.log(`✓ Audio eliminado: ${audioPath}`);
            }
          } catch (error) {
            console.error('Error al eliminar audio:', error);
          }
        }
      }

      // Eliminar todos los resúmenes de la BD
      await Summary.deleteMany({ document: document._id });
      console.log(`✓ ${summaries.length} resúmenes eliminados de la BD`);
    }

    // Eliminar el documento
    await document.deleteOne();

    req.user.stats.totalDocuments = Math.max(0, req.user.stats.totalDocuments - 1);
    req.user.stats.totalSummaries = Math.max(0, req.user.stats.totalSummaries - summaries.length);
    await req.user.save({ validateBeforeSave: false });

    const message = summaries.length > 0
      ? `Documento y ${summaries.length} resumen(es) eliminados exitosamente`
      : 'Documento eliminado exitosamente';

    res.status(200).json({
      success: true,
      message,
      data: {
        deletedSummaries: summaries.length,
      },
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
