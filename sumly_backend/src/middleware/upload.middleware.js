const multer = require('multer');
const path = require('path');
const fs = require('fs');
const config = require('../config/environment');

// Crear directorio de uploads si no existe
const uploadDir = config.uploadDir;
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuración de almacenamiento
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, `${name}-${uniqueSuffix}${ext}`);
  },
});

// Filtro de archivos
const fileFilter = (req, file, cb) => {
  console.log(`📎 Archivo recibido: ${file.originalname}, MIME type: ${file.mimetype}`);

  const allowedTypes = config.allowedFileTypes;
  const ext = path.extname(file.originalname).toLowerCase();
  const allowedExtensions = ['.pdf', '.txt', '.doc', '.docx'];

  // Verificar por MIME type O por extensión
  if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
    console.log('✓ Archivo aceptado');
    cb(null, true);
  } else {
    console.log(`✗ Archivo rechazado - MIME: ${file.mimetype}, Ext: ${ext}`);
    cb(new Error('Tipo de archivo no permitido. Solo PDF, TXT, DOC, DOCX'), false);
  }
};

// Configuración de multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: config.maxFileSize,
  },
  fileFilter: fileFilter,
});

// Manejo de errores de multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'El archivo es demasiado grande. Máximo 50MB',
      });
    }
    return res.status(400).json({
      success: false,
      message: `Error al subir archivo: ${err.message}`,
    });
  } else if (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
  next();
};

module.exports = {
  upload,
  handleMulterError,
};
