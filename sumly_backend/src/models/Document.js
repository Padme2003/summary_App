const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'El documento debe tener un título'],
    trim: true,
  },
  author: {
    type: String,
    default: 'Desconocido',
  },
  type: {
    type: String,
    enum: ['summary', 'audiobook'],
    required: true,
  },
  originalText: {
    type: String,
    required: true,
  },
  processedText: {
    type: String,
  },
  fileName: {
    type: String,
  },
  filePath: {
    type: String,
  },
  fileSize: {
    type: Number,
  },
  audioUrl: {
    type: String,
  },
  audioDuration: {
    type: Number, // in seconds
  },
  chapters: [{
    title: String,
    startTime: Number,
    endTime: Number,
  }],
  status: {
    type: String,
    enum: ['processing', 'completed', 'failed'],
    default: 'processing',
  },
  progress: {
    type: Number,
    default: 0,
    min: 0,
    max: 1,
  },
  isFavorite: {
    type: Boolean,
    default: false,
  },
  lastPlayed: {
    type: Date,
  },
  playbackPosition: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update timestamp on save
documentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Document', documentSchema);
