const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/environment');

class GeminiService {
  constructor() {
    if (!config.geminiApiKey) {
      console.warn('⚠️  GEMINI_API_KEY no configurada. El servicio de resúmenes no funcionará.');
      this.genAI = null;
    } else {
      this.genAI = new GoogleGenerativeAI(config.geminiApiKey);
    }
  }

  async generateSummary(text) {
    if (!this.genAI) {
      throw new Error('API Key de Gemini no configurada');
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });

      const prompt = `
Eres un experto en crear resúmenes concisos y útiles.
Por favor, analiza el siguiente texto y genera un resumen detallado que:

1. Capture las ideas principales y conceptos clave
2. Mantenga la estructura lógica del contenido original
3. Sea conciso pero completo (3-5 páginas de texto)
4. Use viñetas o listas cuando sea apropiado
5. Preserve información importante como nombres, fechas, y datos relevantes

El resumen debe ser fácil de leer y comprender para alguien que no ha leído el documento original.

TEXTO A RESUMIR:
${text}

RESUMEN:
      `;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const summary = response.text();

      return {
        success: true,
        summary: summary.trim(),
        wordCount: summary.split(/\s+/).length,
      };
    } catch (error) {
      console.error('Error generando resumen con Gemini:', error);
      throw new Error(`Error al generar resumen: ${error.message}`);
    }
  }

  async generateChapters(text) {
    if (!this.genAI) {
      throw new Error('API Key de Gemini no configurada');
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });

      const prompt = `
Analiza el siguiente texto y divide su contenido en capítulos lógicos.
Para cada capítulo, proporciona un título descriptivo.
Responde ÚNICAMENTE con un array JSON con el formato:
[
  {"title": "Introducción", "content": "contenido del capítulo..."},
  {"title": "Capítulo 1: ...", "content": "contenido del capítulo..."}
]

TEXTO:
${text.substring(0, 10000)}

JSON:
      `;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      let chaptersText = response.text();

      // Clean up the response to get valid JSON
      chaptersText = chaptersText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

      try {
        const chapters = JSON.parse(chaptersText);
        return { success: true, chapters };
      } catch (parseError) {
        // Fallback: create simple chapters
        return {
          success: true,
          chapters: [
            { title: 'Contenido Completo', content: text }
          ]
        };
      }
    } catch (error) {
      console.error('Error generando capítulos:', error);
      // Return default chapter structure
      return {
        success: true,
        chapters: [
          { title: 'Contenido Completo', content: text }
        ]
      };
    }
  }
}

module.exports = new GeminiService();
