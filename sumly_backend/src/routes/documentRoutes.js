const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const config = require('../config/environment');

const {
  getDocuments,
  getDocument,
  uploadDocument,
  updateDocument,
  deleteDocument,
} = require('../controllers/documentController');

const { protect } = require('../middlewares/auth');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, config.uploadPath);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = /pdf|txt|doc|docx/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Solo se permiten archivos PDF, TXT, DOC y DOCX'));
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: config.maxFileSize },
  fileFilter: fileFilter,
});

// All routes require authentication
router.use(protect);

router.get('/', getDocuments);
router.get('/:id', getDocument);
router.post('/upload', upload.single('file'), uploadDocument);
router.put('/:id', updateDocument);
router.delete('/:id', deleteDocument);

module.exports = router;
