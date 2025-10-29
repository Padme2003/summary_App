const mongoose = require('mongoose');

const summarySchema = new mongoose.Schema({
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
  content: {
    type: String,
    required: true,
  },
  keyPoints: [{
    type: String,
  }],
  sections: [{
    title: String,
    content: String,
    order: Number,
  }],
  metadata: {
    originalWordCount: Number,
    summaryWordCount: Number,
    compressionRatio: Number,
    estimatedReadingTime: Number,
    language: String,
  },
  generationMethod: {
    type: String,
    enum: ['ai-gemini', 'ai-gpt', 'extractive', 'hybrid'],
    default: 'ai-gemini',
  },
  generationTime: {
    type: Number,
  },
  quality: {
    score: {
      type: Number,
      min: 0,
      max: 100,
    },
    feedback: String,
  },
  audioUrl: {
    type: String,
  },
  audioDuration: {
    type: Number,
  },
  status: {
    type: String,
    enum: ['generating', 'completed', 'error'],
    default: 'generating',
  },
  views: {
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
summarySchema.index({ user: 1, createdAt: -1 });
summarySchema.index({ document: 1 });

module.exports = mongoose.model('Summary', summarySchema);
