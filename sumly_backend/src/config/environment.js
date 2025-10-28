require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/sumly_db',
  jwtSecret: process.env.JWT_SECRET || 'default_secret_key',
  jwtExpire: process.env.JWT_EXPIRE || '7d',
  geminiApiKey: process.env.GEMINI_API_KEY,
  maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 52428800, // 50MB
  uploadPath: process.env.UPLOAD_PATH || './uploads',
};
