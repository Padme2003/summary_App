const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config/environment');

// Verificar token JWT
exports.protect = async (req, res, next) => {
  console.log('🔒 Middleware protect - Verificando autenticación:', {
    method: req.method,
    url: req.url,
    hasAuth: !!req.headers.authorization
  });

  try {
    let token;

    // Obtener token del header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      console.log('❌ Auth fallida: No hay token');
      return res.status(401).json({
        success: false,
        message: 'No autorizado. Token no proporcionado',
      });
    }

    try {
      // Verificar token
      const decoded = jwt.verify(token, config.jwtSecret);

      // Obtener usuario
      const user = await User.findById(decoded.id).select('-password');

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Usuario no encontrado',
        });
      }

      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Usuario inactivo',
        });
      }

      req.user = user;
      console.log('✅ Auth exitosa - Usuario:', user.email);
      next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Token inválido o expirado',
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error en la autenticación',
      error: error.message,
    });
  }
};

// Verificar roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `El rol ${req.user.role} no tiene acceso a esta ruta`,
      });
    }
    next();
  };
};

// Generar token JWT
exports.generateToken = (userId) => {
  return jwt.sign({ id: userId }, config.jwtSecret, {
    expiresIn: '30d',
  });
};
