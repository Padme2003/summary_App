const express = require('express');
const cors = require('cors');
const path = require('path');
const connectDB = require('./config/database');
const config = require('./config/environment');

const app = express();

// Conectar a la base de datos
connectDB();

// Middlewares
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Servir archivos estáticos con path absoluto
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
console.log('📁 Sirviendo archivos desde:', path.join(__dirname, '../uploads'));

// Rutas
app.get('/', (req, res) => {
  res.json({
    message: 'API de SUMLY funcionando correctamente',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      documents: '/api/documents',
      summaries: '/api/summaries',
      audiobooks: '/api/audiobooks'
    }
  });
});

// Rutas de la API
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const documentRoutes = require('./routes/document.routes');
const summaryRoutes = require('./routes/summary.routes');
const audiobookRoutes = require('./routes/audiobook.routes');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/summaries', summaryRoutes);
app.use('/api/audiobooks', audiobookRoutes);

// Manejo de errores
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Error interno del servidor',
    error: config.nodeEnv === 'development' ? err : {}
  });
});

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Ruta no encontrada'
  });
});

// Iniciar servidor
const PORT = config.port;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Servidor corriendo en http://0.0.0.0:${PORT}`);
  console.log(`✓ Accesible desde la red en http://192.168.18.54:${PORT}`);
  console.log(`✓ Entorno: ${config.nodeEnv}`);
});

module.exports = app;
