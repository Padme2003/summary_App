const express = require('express');
const router = express.Router();
const documentController = require('../controllers/document.controller');
const { protect } = require('../middleware/auth.middleware');
const { upload, handleMulterError } = require('../middleware/upload.middleware');

// Todas las rutas requieren autenticación
router.use(protect);

// Rutas de documentos
router.post(
  '/upload',
  upload.single('file'),
  handleMulterError,
  documentController.uploadDocument
);

router.post('/text', documentController.uploadText);

router.get('/', documentController.getDocuments);
router.get('/:id', documentController.getDocument);
router.put('/:id', documentController.updateDocument);
router.put('/:id/favorite', documentController.toggleFavorite);
router.delete('/:id', documentController.deleteDocument);

module.exports = router;
