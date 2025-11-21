const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');

// Todas las rutas requieren autenticación
router.use(protect);

// Rutas de usuario
router.get('/profile', authController.getMe);
router.put('/profile', authController.updateProfile);
router.put('/password', authController.changePassword);

module.exports = router;
