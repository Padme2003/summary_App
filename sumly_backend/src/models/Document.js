const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  originalContent: {
    type: String,
    required: true,
  },
  summary: {
    type: String,
  },
  audioUrl: {
    type: String,
  },
  type: {
    type: String,
    enum: ['summary', 'audiobook'],
    required: true,
  },
  status: {
    type: String,
    enum: ['processing', 'completed', 'failed'],
    default: 'processing',
  },
  fileName: {
    type: String,
  },
  fileSize: {
    type: Number,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Document', documentSchema);
