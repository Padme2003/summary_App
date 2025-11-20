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
        message: 'El documento no tiene contenido para resumir. Verifica que el PDF sea válido y contenga texto.',
      });
    }

    // Validar que hay suficiente contenido
    const wordCount = document.content.split(/\s+/).filter(w => w.length > 0).length;
    if (wordCount < 100) {
      return res.status(400).json({
        success: false,
        message: `El documento es muy corto (${wordCount} palabras). Necesita al menos 100 palabras para generar un resumen útil.`,
      });
    }

    // Gemini free tier permite hasta ~25,000 palabras (30k tokens input)
    if (wordCount > 25000) {
      return res.status(400).json({
        success: false,
        message: `El documento es muy largo (${wordCount} palabras). El máximo permitido es 25,000 palabras.`,
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
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `
Eres un experto en crear resúmenes claros y concisos. Analiza el siguiente texto y crea un resumen estructurado.

INSTRUCCIONES IMPORTANTES:
1. Crea un resumen de 3-5 párrafos que capture las ideas principales
2. Identifica 5-7 puntos clave del texto
3. Divide el contenido en secciones lógicas (Introducción, Desarrollo, Conclusión)
4. Usa un lenguaje claro y profesional en español
5. Mantén la objetividad del texto original

⚠️ FORMATO DE RESPUESTA - MUY IMPORTANTE:
Debes responder ÚNICAMENTE con un objeto JSON válido, sin texto adicional antes o después.
NO uses markdown, NO uses bloques de código (```), SOLO el JSON puro.

TEXTO A RESUMIR:
${document.content.substring(0, 30000)}

FORMATO EXACTO DE RESPUESTA (copia este formato):
{
  "summary": "Tu resumen completo aquí en 3-5 párrafos separados por saltos de línea...",
  "keyPoints": ["Punto clave 1", "Punto clave 2", "Punto clave 3"],
  "sections": [
    {"title": "Introducción", "content": "Contenido de la introducción"},
    {"title": "Desarrollo", "content": "Contenido del desarrollo"},
    {"title": "Conclusión", "content": "Contenido de la conclusión"}
  ]
}

Responde SOLO con el JSON, nada más.
`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();

    // Limpiar la respuesta (remover markdown y cualquier formato de código)
    text = text
      .replace(/```json\n?/g, '')  // Remover ```json
      .replace(/```javascript\n?/g, '')  // Remover ```javascript
      .replace(/```\n?/g, '')  // Remover ``` restantes
      .replace(/^[\s\n]+/, '')  // Remover espacios y saltos de línea al inicio
      .replace(/[\s\n]+$/, '')  // Remover espacios y saltos de línea al final
      .trim();

    console.log('🤖 Respuesta de Gemini (primeros 500 caracteres):', text.substring(0, 500));

    let summaryData;
    try {
      summaryData = JSON.parse(text);

      // Validar estructura
      if (!summaryData.summary || typeof summaryData.summary !== 'string') {
        console.error('❌ Estructura de resumen inválida');
        throw new Error('Invalid summary structure');
      }

      console.log('✅ JSON parseado correctamente');
      console.log('   - Resumen:', summaryData.summary.length, 'caracteres');
      console.log('   - Puntos clave:', summaryData.keyPoints?.length || 0);
      console.log('   - Secciones:', summaryData.sections?.length || 0);

    } catch (parseError) {
      console.error('❌ Error parseando JSON:', parseError.message);
      console.log('Respuesta completa (primeros 1000 chars):', text.substring(0, 1000));

      // Gemini no devolvió JSON válido - extraer el resumen manualmente
      // A veces Gemini ignora el formato y solo devuelve texto plano
      let cleanText = text;

      // Limpiar cualquier formato residual de código/llaves
      cleanText = cleanText
        .replace(/^\{+/, '')  // Quitar llaves al inicio
        .replace(/\}+$/, '')  // Quitar llaves al final
        .replace(/"summary":\s*"/gi, '')  // Quitar "summary": "
        .replace(/"keyPoints":\s*\[.*?\]/gi, '')  // Quitar sección keyPoints
        .replace(/"sections":\s*\[.*?\]/gi, '')  // Quitar sección sections
        .replace(/,\s*$/g, '')  // Quitar comas finales
        .trim();

      summaryData = {
        summary: cleanText,
        keyPoints: [],
        sections: [],
      };

      console.log('⚠️ Usando texto limpio sin JSON:', cleanText.substring(0, 200));
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

    // NOTA: Audio generation deshabilitado - requiere Google Cloud TTS (costoso)
    // Los usuarios pueden usar TTS nativo del dispositivo para escuchar resúmenes
    // Si quieres habilitar audio del backend:
    // 1. Configura Google Cloud TTS credentials
    // 2. Descomenta el código a continuación
    /*
    try {
      console.log('🎵 Iniciando generación de audio del resumen...');
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

      console.log(`✅ Audio del resumen generado exitosamente`);
    } catch (audioError) {
      console.error('❌ Error al generar audio:', audioError.message);
      summary.metadata = summary.metadata || {};
      summary.metadata.audioGenerationError = audioError.message;
    }
    */

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

    let errorMessage = 'Error desconocido al generar el resumen.';

    if (error.message && error.message.includes('API key')) {
      errorMessage = 'Error con la clave de API de Gemini. Verifica tu configuración.';
    } else if (error.message && error.message.includes('quota')) {
      errorMessage = 'Límite de cuota de API excedido. Intenta más tarde.';
    } else if (error.message && error.message.includes('model')) {
      errorMessage = 'El modelo de IA no está disponible. Contacta al administrador.';
    } else if (error.message) {
      errorMessage = error.message;
    }

    summary.status = 'error';
    summary.content = `No se pudo generar el resumen: ${errorMessage}`;
    await summary.save();

    console.log(`❌ Resumen marcado como error: ${summary._id}`);
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
