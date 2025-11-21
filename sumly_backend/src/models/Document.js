const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'El título es requerido'],
    trim: true,
  },
  originalFileName: {
    type: String,
    required: true,
  },
  filePath: {
    type: String,
  },
  fileSize: {
    type: Number,
  },
  fileType: {
    type: String,
    enum: ['pdf', 'txt', 'doc', 'docx', 'text'],
    required: true,
  },
  content: {
    type: String,
  },
  metadata: {
    pages: Number,
    wordCount: Number,
    language: String,
    author: String,
  },
  status: {
    type: String,
    enum: ['uploaded', 'processing', 'completed', 'error'],
    default: 'uploaded',
  },
  tags: [String],
  category: {
    type: String,
    enum: ['general', 'academic', 'business', 'literature', 'other'],
    default: 'general',
  },
  isFavorite: {
    type: Boolean,
    default: false,
  },
  summary: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Summary',
  },
  audiobook: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Audiobook',
  },
}, {
  timestamps: true,
});

// Índices para búsqueda
documentSchema.index({ user: 1, createdAt: -1 });
documentSchema.index({ title: 'text', 'metadata.author': 'text' });

module.exports = mongoose.model('Document', documentSchema);
