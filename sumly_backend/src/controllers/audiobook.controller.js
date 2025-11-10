const Audiobook = require('../models/Audiobook');
const Document = require('../models/Document');
const User = require('../models/User');
const { generateAudiobook, generateAudioFile } = require('../services/tts.service');

// Obtener cuota de audiolibros del usuario
exports.getAudiobookQuota = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    // Verificar y resetear cuota si es necesario
    user.checkAndResetAudiobookQuota();
    await user.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      data: {
        quota: {
          used: user.audiobookQuota.used,
          limit: user.audiobookQuota.limit,
          remaining: user.audiobookQuota.limit === -1
            ? -1
            : Math.max(0, user.audiobookQuota.limit - user.audiobookQuota.used),
          resetDate: user.audiobookQuota.resetDate,
          isPremium: user.subscription.type === 'premium' || user.audiobookQuota.limit === -1,
        },
      },
    });
  } catch (error) {
    console.error('Error al obtener cuota:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener cuota de audiolibros',
      error: error.message,
    });
  }
};

// Generar audiolibro completo
exports.generateAudiobook = async (req, res) => {
  try {
    const { documentId, voice, speed } = req.body;

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
        message: 'El documento no tiene contenido para convertir a audio',
      });
    }

    // Obtener usuario con información completa
    const user = await User.findById(req.user._id);

    // Verificar cuota disponible
    if (!user.hasAudiobookQuota()) {
      return res.status(403).json({
        success: false,
        message: 'Has alcanzado tu límite de audiolibros este mes',
        code: 'QUOTA_EXCEEDED',
        data: {
          quota: {
            used: user.audiobookQuota.used,
            limit: user.audiobookQuota.limit,
            resetDate: user.audiobookQuota.resetDate,
          },
          suggestion: 'Usa TTS nativo del dispositivo o actualiza a Premium para audiolibros ilimitados',
        },
      });
    }

    // Crear audiolibro inicial
    const audiobook = await Audiobook.create({
      document: document._id,
      user: req.user._id,
      title: `Audiolibro: ${document.title}`,
      voice: voice || 'default',
      speed: speed || 1.0,
      status: 'generating',
    });

    // Incrementar contador de cuota
    user.audiobookQuota.used += 1;
    await user.save({ validateBeforeSave: false });

    // Generar audio en segundo plano
    generateAudiobookAsync(document, audiobook, user, { voice, speed });

    res.status(202).json({
      success: true,
      message: 'Generación de audiolibro iniciada con Google Cloud TTS',
      data: {
        audiobook,
        quota: {
          used: user.audiobookQuota.used,
          limit: user.audiobookQuota.limit,
          remaining: user.audiobookQuota.limit === -1
            ? -1
            : Math.max(0, user.audiobookQuota.limit - user.audiobookQuota.used),
        },
      },
    });
  } catch (error) {
    console.error('Error al generar audiolibro:', error);
    res.status(500).json({
      success: false,
      message: 'Error al generar audiolibro',
      error: error.message,
    });
  }
};

// Función asíncrona para generar el audiolibro
async function generateAudiobookAsync(document, audiobook, user, options) {
  const startTime = Date.now();

  try {
    const baseFilename = `audiobook_${audiobook._id}`;

    // Generar capítulos de audio
    const chapters = await generateAudiobook(
      document.content,
      baseFilename,
      {
        languageCode: 'es-ES',
        voiceName: options.voice || 'es-ES-Standard-A',
        speed: options.speed || 1.0,
      },
    );

    // Calcular duración total
    const totalDuration = chapters.reduce((sum, ch) => sum + ch.duration, 0);

    // Actualizar audiolibro
    audiobook.chapters = chapters;
    audiobook.duration = totalDuration;
    audiobook.status = 'completed';
    audiobook.generationTime = Math.round((Date.now() - startTime) / 1000);

    // Si hay solo un capítulo, usar su URL como URL principal
    if (chapters.length === 1) {
      audiobook.audioUrl = chapters[0].audioUrl;
    }

    await audiobook.save();

    // Actualizar documento
    document.audiobook = audiobook._id;
    await document.save();

    // Actualizar estadísticas del usuario
    user.stats.totalAudiobooks += 1;
    await user.save({ validateBeforeSave: false });

    console.log(`✅ Audiolibro generado exitosamente: ${audiobook._id}`);
  } catch (error) {
    console.error('Error al generar audiolibro:', error);
    audiobook.status = 'error';
    await audiobook.save();
  }
}

// Obtener todos los audiolibros del usuario
exports.getAudiobooks = async (req, res) => {
  try {
    const { isFavorite } = req.query;

    const filter = { user: req.user._id };
    if (isFavorite) filter.isFavorite = isFavorite === 'true';

    const audiobooks = await Audiobook.find(filter)
      .populate('document')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: audiobooks.length,
      data: {
        audiobooks,
      },
    });
  } catch (error) {
    console.error('Error al obtener audiolibros:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener audiolibros',
      error: error.message,
    });
  }
};

// Obtener un audiolibro por ID
exports.getAudiobook = async (req, res) => {
  try {
    const audiobook = await Audiobook.findOne({
      _id: req.params.id,
      user: req.user._id,
    }).populate('document');

    if (!audiobook) {
      return res.status(404).json({
        success: false,
        message: 'Audiolibro no encontrado',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        audiobook,
      },
    });
  } catch (error) {
    console.error('Error al obtener audiolibro:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener audiolibro',
      error: error.message,
    });
  }
};

// Actualizar posición de reproducción
exports.updatePlaybackPosition = async (req, res) => {
  try {
    const { position } = req.body;

    const audiobook = await Audiobook.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!audiobook) {
      return res.status(404).json({
        success: false,
        message: 'Audiolibro no encontrado',
      });
    }

    audiobook.currentPosition = position;
    audiobook.playbackHistory.push({
      position: position,
      timestamp: new Date(),
    });

    await audiobook.save();

    res.status(200).json({
      success: true,
      message: 'Posición actualizada',
      data: {
        currentPosition: audiobook.currentPosition,
      },
    });
  } catch (error) {
    console.error('Error al actualizar posición:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar posición',
      error: error.message,
    });
  }
};

// Actualizar audiolibro (favorito, etc.)
exports.updateAudiobook = async (req, res) => {
  try {
    const allowedFields = ['isFavorite', 'currentPosition'];
    const updates = {};

    Object.keys(req.body).forEach((key) => {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    const audiobook = await Audiobook.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      updates,
      { new: true, runValidators: true },
    );

    if (!audiobook) {
      return res.status(404).json({
        success: false,
        message: 'Audiolibro no encontrado',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Audiolibro actualizado',
      data: {
        audiobook,
      },
    });
  } catch (error) {
    console.error('Error al actualizar audiolibro:', error);
    res.status(500).json({
      success: false,
      message: 'Error al actualizar audiolibro',
      error: error.message,
    });
  }
};

// Eliminar audiolibro
exports.deleteAudiobook = async (req, res) => {
  try {
    const audiobook = await Audiobook.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!audiobook) {
      return res.status(404).json({
        success: false,
        message: 'Audiolibro no encontrado',
      });
    }

    // TODO: Eliminar archivos de audio del sistema de archivos

    await audiobook.deleteOne();

    req.user.stats.totalAudiobooks = Math.max(
      0,
      req.user.stats.totalAudiobooks - 1,
    );
    await req.user.save({ validateBeforeSave: false });

    res.status(200).json({
      success: true,
      message: 'Audiolibro eliminado',
    });
  } catch (error) {
    console.error('Error al eliminar audiolibro:', error);
    res.status(500).json({
      success: false,
      message: 'Error al eliminar audiolibro',
      error: error.message,
    });
  }
};
