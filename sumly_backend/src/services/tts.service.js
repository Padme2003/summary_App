const textToSpeech = require('@google-cloud/text-to-speech');
const fs = require('fs').promises;
const path = require('path');
const config = require('../config/environment');

// Cliente de Google Text-to-Speech
let ttsClient;

// Inicializar cliente si hay credenciales
try {
  if (process.env.GOOGLE_TTS_CREDENTIALS) {
    // Railway: Credenciales desde variable de entorno (JSON string)
    const credentials = JSON.parse(process.env.GOOGLE_TTS_CREDENTIALS);
    ttsClient = new textToSpeech.TextToSpeechClient({ credentials });
    console.log('✅ Google TTS inicializado desde variable de entorno');
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    // Local: Credenciales desde archivo
    ttsClient = new textToSpeech.TextToSpeechClient();
    console.log('✅ Google TTS inicializado desde archivo de credenciales');
  }
} catch (error) {
  console.warn('⚠️  Google TTS no configurado. Usando modo simulación.');
  console.error('Error al inicializar TTS:', error.message);
}

/**
 * Convierte texto a audio usando Google Text-to-Speech
 * @param {string} text - Texto a convertir
 * @param {object} options - Opciones de voz
 * @returns {Promise<{audioBuffer: Buffer, duration: number}>}
 */
async function textToSpeech_Google(text, options = {}) {
  if (!ttsClient) {
    throw new Error(
      'Google TTS no está configurado. Configura GOOGLE_APPLICATION_CREDENTIALS',
    );
  }

  const request = {
    input: { text: text },
    voice: {
      languageCode: options.languageCode || 'es-ES',
      name: options.voiceName || 'es-ES-Standard-A',
      ssmlGender: options.gender || 'NEUTRAL',
    },
    audioConfig: {
      audioEncoding: 'MP3',
      speakingRate: options.speed || 1.0,
      pitch: options.pitch || 0.0,
      volumeGainDb: options.volume || 0.0,
    },
  };

  const [response] = await ttsClient.synthesizeSpeech(request);

  // Calcular duración aproximada (palabras por minuto)
  const words = text.split(/\s+/).length;
  const wordsPerMinute = 150 * (options.speed || 1.0);
  const duration = Math.ceil((words / wordsPerMinute) * 60);

  return {
    audioBuffer: response.audioContent,
    duration: duration,
  };
}

/**
 * Genera audio usando una alternativa más simple (ElevenLabs, OpenAI, etc.)
 * Esta es una implementación de respaldo que puedes personalizar
 */
async function textToSpeech_Alternative(text, options = {}) {
  // OPCIÓN 1: Usar OpenAI TTS (más simple, no requiere credenciales de Google)
  // Descomenta esto si quieres usar OpenAI TTS
  /*
  const OpenAI = require('openai');
  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

  const mp3 = await openai.audio.speech.create({
    model: "tts-1",
    voice: options.voice || "nova",
    input: text,
    speed: options.speed || 1.0,
  });

  const buffer = Buffer.from(await mp3.arrayBuffer());
  const words = text.split(/\s+/).length;
  const duration = Math.ceil((words / 150) * 60);

  return {
    audioBuffer: buffer,
    duration: duration,
  };
  */

  // OPCIÓN 2: Por ahora, crear un audio simulado para desarrollo
  console.log('⚠️  Generando audio simulado. Configura un servicio TTS real.');

  const words = text.split(/\s+/).length;
  const duration = Math.ceil((words / 150) * 60);

  // Crear un buffer vacío (en producción, usa un servicio real)
  const audioBuffer = Buffer.from('AUDIO_PLACEHOLDER');

  return {
    audioBuffer: audioBuffer,
    duration: duration,
  };
}

/**
 * Genera audio y lo guarda en el sistema de archivos
 * @param {string} text - Texto a convertir
 * @param {string} filename - Nombre del archivo
 * @param {object} options - Opciones de voz
 * @returns {Promise<{audioPath: string, duration: number}>}
 */
async function generateAudioFile(text, filename, options = {}) {
  try {
    // Crear directorio de audio si no existe
    const audioDir = path.join(config.uploadDir, 'audio');
    await fs.mkdir(audioDir, { recursive: true });

    let audioData;

    // Intentar usar Google TTS primero, si no, usar alternativa
    if (ttsClient) {
      audioData = await textToSpeech_Google(text, options);
    } else {
      audioData = await textToSpeech_Alternative(text, options);
    }

    // Guardar archivo
    const audioPath = path.join(audioDir, `${filename}.mp3`);
    await fs.writeFile(audioPath, audioData.audioBuffer);

    return {
      audioPath: audioPath,
      audioUrl: `/uploads/audio/${filename}.mp3`,
      duration: audioData.duration,
      fileSize: audioData.audioBuffer.length,
    };
  } catch (error) {
    console.error('Error al generar audio:', error);
    throw error;
  }
}

/**
 * Divide texto largo en chunks para procesamiento por partes
 * @param {string} text - Texto completo
 * @param {number} maxChars - Máximo de caracteres por chunk
 * @returns {Array<string>}
 */
function splitTextIntoChunks(text, maxChars = 5000) {
  const chunks = [];
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];

  let currentChunk = '';

  for (const sentence of sentences) {
    if (currentChunk.length + sentence.length > maxChars) {
      if (currentChunk) chunks.push(currentChunk.trim());
      currentChunk = sentence;
    } else {
      currentChunk += sentence;
    }
  }

  if (currentChunk) chunks.push(currentChunk.trim());

  return chunks;
}

/**
 * Genera audio para un texto largo dividiéndolo en capítulos
 * @param {string} text - Texto completo
 * @param {string} baseFilename - Nombre base para archivos
 * @param {object} options - Opciones de voz
 * @returns {Promise<Array<{chapterNumber: number, audioUrl: string, duration: number}>>}
 */
async function generateAudiobook(text, baseFilename, options = {}) {
  const chunks = splitTextIntoChunks(text, 5000);
  const chapters = [];

  for (let i = 0; i < chunks.length; i++) {
    const chapterFilename = `${baseFilename}_chapter_${i + 1}`;

    const audioResult = await generateAudioFile(
      chunks[i],
      chapterFilename,
      options,
    );

    chapters.push({
      chapterNumber: i + 1,
      title: `Capítulo ${i + 1}`,
      audioUrl: audioResult.audioUrl,
      duration: audioResult.duration,
      order: i + 1,
      startTime: chapters.reduce((sum, ch) => sum + ch.duration, 0),
    });
  }

  return chapters;
}

module.exports = {
  generateAudioFile,
  generateAudiobook,
  splitTextIntoChunks,
};
