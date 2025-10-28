const pdfParse = require('pdf-parse');
const fs = require('fs').promises;

class PDFService {
  async extractText(filePath) {
    try {
      const dataBuffer = await fs.readFile(filePath);
      const data = await pdfParse(dataBuffer);

      return {
        success: true,
        text: data.text,
        pages: data.numpages,
        info: data.info,
      };
    } catch (error) {
      console.error('Error extrayendo texto del PDF:', error);
      throw new Error(`Error al procesar PDF: ${error.message}`);
    }
  }

  async extractMetadata(filePath) {
    try {
      const dataBuffer = await fs.readFile(filePath);
      const data = await pdfParse(dataBuffer);

      return {
        title: data.info?.Title || 'Sin título',
        author: data.info?.Author || 'Desconocido',
        pages: data.numpages,
        creationDate: data.info?.CreationDate,
      };
    } catch (error) {
      console.error('Error extrayendo metadatos:', error);
      return {
        title: 'Sin título',
        author: 'Desconocido',
        pages: 0,
      };
    }
  }
}

module.exports = new PDFService();
