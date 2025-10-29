const mongoose = require('mongoose');
const config = require('./environment');

const connectDB = async () => {
  try {
    await mongoose.connect(config.mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log(' MongoDB conectado correctamente');
  } catch (error) {
    console.error('L Error al conectar a MongoDB:', error.message);
    process.exit(1);
  }
};

mongoose.connection.on('disconnected', () => {
  console.log('   MongoDB desconectado');
});

mongoose.connection.on('error', (err) => {
  console.error('L Error en MongoDB:', err);
});

module.exports = connectDB;
