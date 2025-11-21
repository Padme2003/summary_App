const mongoose = require('mongoose');

const audiobookSchema = new mongoose.Schema({
  document: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Document',
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  chapters: [{
    title: String,
    audioUrl: String,
    duration: Number,
    order: Number,
    startTime: Number,
  }],
  audioUrl: {
    type: String,
  },
  duration: {
    type: Number,
  },
  format: {
    type: String,
    enum: ['mp3', 'wav', 'ogg'],
    default: 'mp3',
  },
  voice: {
    type: String,
    default: 'default',
  },
  speed: {
    type: Number,
    default: 1.0,
  },
  status: {
    type: String,
    enum: ['generating', 'completed', 'error'],
    default: 'generating',
  },
  generationTime: {
    type: Number,
  },
  fileSize: {
    type: Number,
  },
  playbackHistory: [{
    position: Number,
    timestamp: Date,
  }],
  currentPosition: {
    type: Number,
    default: 0,
  },
  isFavorite: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

// Índices
audiobookSchema.index({ user: 1, createdAt: -1 });
audiobookSchema.index({ document: 1 });

module.exports = mongoose.model('Audiobook', audiobookSchema);
