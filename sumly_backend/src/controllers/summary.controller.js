const Summary = require('../models/Summary');
const Document = require('../models/Document');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { generateAudioFile } = require('../services/tts.service');
const config = require('../config/environment');

// Inicializar Gemini AI
const genAI = new GoogleGenerativeAI(config.geminiApiKey);

// Generar resumen con IA
exports.generateSummary = async (req, res) => {
  try {
    const { documentId } = req.body;

    const document = await Document.findOne({
      _id: documentId,
      user: req.user._id,
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Documento no encontrado',
      });
    }

    if (!document.content || document.content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'El documento no tiene contenido para resumir',
      });
    }

    const startTime = Date.now();

    // Crear resumen inicial
    const summary = await Summary.create({
      document: document._id,
      user: req.user._id,
      title: `Resumen: ${document.title}`,
      content: 'Generando resumen...',
      status: 'generating',
    });

    // Generar resumen con Gemini en segundo plano
    generateSummaryWithAI(document, summary, req.user);

    res.status(202).json({
      success: true,
      message: 'Generación de resumen iniciada',
      data: {
        summary,
      },
    });
  } catch (error) {
    console.error('Error al generar resumen:', error);
    res.status(500).json({
      success: false,
      message: 'Error al generar resumen',
      error: error.message,
    });
  }
};

// Función para generar resumen con IA (asíncrona)
async function generateSummaryWithAI(document, summary, user) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `
Eres un experto en crear resúmenes claros y concisos. Analiza el siguiente texto y crea un resumen estructurado.

INSTRUCCIONES:
1. Crea un resumen de 3-5 párrafos que capture las ideas principales
2. Identifica 5-7 puntos clave del texto
3. Divide el contenido en secciones lógicas (Introducción, Desarrollo, Conclusión)
4. Usa un lenguaje claro y profesional
5. Mantén la objetividad del texto original

TEXTO A RESUMIR:
${document.content.substring(0, 30000)}

FORMATO DE RESPUESTA (JSON):
{
  "summary": "Resumen completo en 3-5 párrafos...",
  "keyPoints": ["Punto 1", "Punto 2", "..."],
  "sections": [
    {"title": "Introducción", "content": "..."},
    {"title": "Desarrollo", "content": "..."},
    {"title": "Conclusión", "content": "..."}
  ]
}
`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();

    // Limpiar la respuesta (remover markdown si existe)
    text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    let summaryData;
    try {
      summaryData = JSON.parse(text);
    } catch (parseError) {
      // Si no es JSON válido, usar el texto directamente
      summaryData = {
        summary: text,
        keyPoints: [],
        sections: [],
      };
    }

    const endTime = Date.now();
    const generationTime = Math.round((endTime - summary.createdAt) / 1000);

    const originalWordCount = document.content.split(/\s+/).length;
    const summaryWordCount = summaryData.summary.split(/\s+/).length;
    const estimatedReadingTime = Math.ceil(summaryWordCount / 200);

    // Actualizar resumen
    summary.content = summaryData.summary;
    summary.keyPoints = summaryData.keyPoints || [];
    summary.sections = summaryData.sections || [];
    summary.status = 'completed';
    summary.generationTime = generationTime;
    summary.metadata = {
      originalWordCount,
      summaryWordCount,
      compressionRatio: Math.round((summaryWordCount / originalWordCount) * 100),
      estimatedReadingTime,
      language: 'es',
    };

    // Generar audio del resumen
    try {
      const audioFilename = `summary_${summary._id}`;
      const audioResult = await generateAudioFile(
        summaryData.summary,
        audioFilename,
        {
          languageCode: 'es-ES',
          voiceName: 'es-ES-Standard-A',
          speed: 1.0,
        },
      );

      summary.audioUrl = audioResult.audioUrl;
      summary.audioDuration = audioResult.duration;

      console.log(`✅ Audio del resumen generado: ${audioResult.audioUrl}`);
    } catch (audioError) {
      console.error('Error al generar audio del resumen:', audioError);
      // Continuar sin audio si hay error
    }

    await summary.save();

    // Actualizar documento
    document.summary = summary._id;
    await document.save();

    // Actualizar estadísticas del usuario
    user.stats.totalSummaries += 1;
    await user.save({ validateBeforeSave: false });

    console.log(`✅ Resumen generado exitosamente: ${summary._id}`);
  } catch (error) {
    console.error('❌ Error al generar resumen con IA:', error);
    console.error('Detalles del error:', error.message);
    console.error('Stack trace:', error.stack);

    summary.status = 'error';
    summary.content = `Error al generar el resumen: ${error.message || 'Error desconocido'}. Por favor, intenta nuevamente.`;
    await summary.save();
  }
}

// Obtener todos los resúmenes del usuario
exports.getSummaries = async (req, res) => {
  try {
    const { isFavorite } = req.query;

    const filter = { user: req.user._id };
    if (isFavorite) filter.isFavorite = isFavorite === 'true';

    const summaries = await Summary.find(filter)
      .populate('document')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: summaries.length,
      data: {
        summaries,
      },
    });
  } catch (error) {
    console.error('Error al obtener resúmenes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener resúmenes',
      error: error.message,
    });
  }
};

// Obtener un resumen por ID
exports.getSummary = async (req, res) => {
  try {
    const summary = await Summary.findOne({
      _id: req.params.id,
      user: req.user._id,
    }).populate('document');

    if (!summary) {
      return res.status(404).json({
        success: false,
        message: 'Resumen no encontrado',
      });
    }

    // Incrementar vistas
    summary.views += 1;
    await summary.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      data: {
        summary,
      },
    });
  } catch (error) {
    console.error('Error al obtener resumen:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener resumen',
      error: error.message,
    });
  }
};

// Actualizar resumen
exports.updateSummary = async (req, res) => {
  try {
    const allowedFields = ['isFavorite', 'quality'];
    const updates = {};

    Object.keys(req.body).forEach((key) => {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    const summary = await Summary.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      updates,
      { new: true, runValidators: true }
    );

    if (!summary) {
      return res.status(404).json({
        success: false,
        message: 'Resumen no encontrado',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Resumen actualizado exitosamente',
      data: {
        summary,
      },
    });
  } catch (error) {
    console.error('Error al actualizar resumen:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar resumen',
      error: error.message,
    });
  }
};

// Alternar favorito
exports.toggleFavorite = async (req, res) => {
  try {
    const summary = await Summary.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!summary) {
      return res.status(404).json({
        success: false,
        message: 'Resumen no encontrado',
      });
    }

    summary.isFavorite = !summary.isFavorite;
    await summary.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      message: summary.isFavorite ? 'Agregado a favoritos' : 'Removido de favoritos',
      data: {
        summary,
      },
    });
  } catch (error) {
    console.error('Error al alternar favorito:', error);
    res.status(500).json({
      success: false,
      message: 'Error al alternar favorito',
      error: error.message,
    });
  }
};

// Eliminar resumen
exports.deleteSummary = async (req, res) => {
  try {
    const summary = await Summary.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!summary) {
      return res.status(404).json({
        success: false,
        message: 'Resumen no encontrado',
      });
    }

    await summary.deleteOne();

    req.user.stats.totalSummaries = Math.max(0, req.user.stats.totalSummaries - 1);
    await req.user.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      message: 'Resumen eliminado exitosamente',
    });
  } catch (error) {
    console.error('Error al eliminar resumen:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar resumen',
      error: error.message,
    });
  }
};
