const express = require('express');
const router = express.Router();
const summaryController = require('../controllers/summary.controller');
const { protect } = require('../middleware/auth.middleware');

// Todas las rutas requieren autenticación
router.use(protect);

// Rutas de resúmenes
router.post('/generate', summaryController.generateSummary);
router.get('/', summaryController.getSummaries);
router.get('/:id', summaryController.getSummary);
router.put('/:id', summaryController.updateSummary);
router.put('/:id/favorite', summaryController.toggleFavorite);
router.delete('/:id', summaryController.deleteSummary);

module.exports = router;
