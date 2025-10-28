const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/environment');

// Inicializar Gemini AI
const genAI = new GoogleGenerativeAI(config.geminiApiKey);

// Generar resumen con IA
exports.generateSummary = async (content) => {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    const prompt = `
      Por favor, genera un resumen completo y detallado del siguiente texto.
      El resumen debe:
      - Ser conciso pero completo (3-5 páginas aproximadamente)
      - Capturar todos los puntos clave y conceptos importantes
      - Mantener la estructura lógica del contenido original
      - Estar en español
      - Ser fácil de entender

      Texto a resumir:
      ${content}

      Proporciona el resumen en formato de texto limpio, bien estructurado con párrafos y secciones si es apropiado.
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const summary = response.text();

    return summary;
  } catch (error) {
    console.error('Error al generar resumen con IA:', error);
    throw new Error('Error al procesar el contenido con IA');
  }
};

// Dividir texto en capítulos (para audiolibros)
exports.divideIntoChapters = async (content) => {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    const prompt = `
      Divide el siguiente texto en capítulos lógicos y coherentes.
      Proporciona la respuesta en formato JSON con la siguiente estructura:
      {
        "chapters": [
          {
            "title": "Título del capítulo",
            "content": "Contenido del capítulo"
          }
        ]
      }

      Texto:
      ${content}
    `;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Intentar parsear JSON de la respuesta
    try {
      const chapters = JSON.parse(text);
      return chapters;
    } catch (parseError) {
      // Si no es JSON válido, crear un capítulo único
      return {
        chapters: [
          {
            title: 'Capítulo 1',
            content: content,
          },
        ],
      };
    }
  } catch (error) {
    console.error('Error al dividir en capítulos:', error);
    // Retornar contenido completo como un solo capítulo
    return {
      chapters: [
        {
          title: 'Capítulo 1',
          content: content,
        },
      ],
    };
  }
};
