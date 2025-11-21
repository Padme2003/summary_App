const express = require('express');
const router = express.Router();
const audiobookController = require('../controllers/audiobook.controller');
const { protect } = require('../middleware/auth.middleware');

// Todas las rutas requieren autenticación
router.use(protect);

// Rutas de audiolibros
router.get('/quota', audiobookController.getAudiobookQuota);
router.post('/generate', audiobookController.generateAudiobook);
router.get('/', audiobookController.getAudiobooks);
router.get('/:id', audiobookController.getAudiobook);
router.put('/:id', audiobookController.updateAudiobook);
router.put('/:id/position', audiobookController.updatePlaybackPosition);
router.delete('/:id', audiobookController.deleteAudiobook);

module.exports = router;
