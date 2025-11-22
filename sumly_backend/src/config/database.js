const mongoose = require('mongoose');
const config = require('./environment');

const connectDB = async () => {
  try {
    await mongoose.connect(config.mongoUri);
    console.log(' MongoDB conectado correctamente');
  } catch (error) {
    console.error('L Error al conectar a MongoDB:', error.message);
    console.log('⚠️  ADVERTENCIA: Servidor iniciando SIN MongoDB. Verifica tu conexión a internet.');
    // NO cerrar el servidor - permitir que arranque sin DB para debugging
    // process.exit(1);
  }
};

mongoose.connection.on('disconnected', () => {
  console.log('�  MongoDB desconectado');
});

mongoose.connection.on('error', (err) => {
  console.error('L Error en MongoDB:', err);
});

module.exports = connectDB;
