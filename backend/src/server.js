require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

require('./config/database'); // inisialisasi & migrasi skema saat startup

const profileRoutes = require('./routes/profileRoutes');
const frameRoutes = require('./routes/frameRoutes');
const filterRoutes = require('./routes/filterRoutes');
const sessionRoutes = require('./routes/sessionRoutes');
const photoRoutes = require('./routes/photoRoutes');
const decorationRoutes = require('./routes/decorationRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const uploadRoutes = require('./routes/uploadRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// File statis hasil upload (foto strip, thumbnail, dll) - diakses Flutter via Image.network
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Photobooth API is running 🎬',
    docs: 'Lihat README.md pada folder backend untuk daftar endpoint',
  });
});

app.use('/api/profile', profileRoutes);
app.use('/api/frames', frameRoutes);
app.use('/api/filters', filterRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/photos', photoRoutes);
app.use('/api/decorations', decorationRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/uploads', uploadRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' });
});

// Error handler global
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ success: false, message: err.message || 'Terjadi kesalahan pada server' });
});

app.listen(PORT, () => {
  console.log(`✅ Photobooth API berjalan di http://localhost:${PORT}`);
});

module.exports = app;
