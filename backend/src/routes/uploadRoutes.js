const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');

// POST /api/uploads -> upload single image, kembalikan path relatif yang bisa
// disimpan ke kolom image_path (photos) / thumbnail_path (frames, filters) /
// content (decorations, untuk tipe sticker berbasis gambar)
router.post('/', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'File gambar wajib diunggah' });
  }
  const relativePath = `/uploads/${req.file.filename}`;
  res.status(201).json({
    success: true,
    message: 'Upload berhasil',
    data: { path: relativePath, filename: req.file.filename },
  });
});

module.exports = router;
