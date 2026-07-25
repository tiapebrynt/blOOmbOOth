const { DEFAULT_USER_ID } = require('../config/constants');
const SessionModel = require('../models/sessionModel');
const PhotoModel = require('../models/photoModel');
const DecorationModel = require('../models/decorationModel');

// GET /api/sessions -> My Gallery (list semua strip milik user login)
exports.getAll = (req, res) => {
  const sessions = SessionModel.findAllByUser(DEFAULT_USER_ID);
  res.json({ success: true, data: sessions });
};

// GET /api/sessions/:id -> Strip Detail (lengkap dengan photos & decorations)
exports.getOne = (req, res) => {
  if (!SessionModel.belongsToUser(req.params.id, DEFAULT_USER_ID)) {
    return res.status(404).json({ success: false, message: 'Strip tidak ditemukan' });
  }
  const session = SessionModel.findDetailById(req.params.id);
  res.json({ success: true, data: session });
};

// POST /api/sessions -> dipanggil dari Final Preview saat user menyimpan hasil photobooth
exports.create = (req, res) => {
  const { frame_id, title, layout_type, photos } = req.body;
  const session = SessionModel.create({
    user_id: DEFAULT_USER_ID,
    frame_id,
    title,
    layout_type,
  });

  // Jika Final Preview mengirim langsung daftar foto, simpan sekaligus
  if (Array.isArray(photos)) {
    photos.forEach((p, idx) => {
      PhotoModel.create({
        session_id: session.id,
        filter_id: p.filter_id,
        image_path: p.image_path,
        order_index: p.order_index ?? idx,
        beauty_smooth: p.beauty_smooth,
        beauty_brighten: p.beauty_brighten,
      });
    });
  }

  const detail = SessionModel.findDetailById(session.id);
  res.status(201).json({ success: true, message: 'Strip berhasil disimpan ke galeri', data: detail });
};

// PUT /api/sessions/:id -> Decorate Strip (ganti frame/judul) atau tandai favorit
exports.update = (req, res) => {
  if (!SessionModel.belongsToUser(req.params.id, DEFAULT_USER_ID)) {
    return res.status(404).json({ success: false, message: 'Strip tidak ditemukan' });
  }
  const updated = SessionModel.update(req.params.id, req.body);
  res.json({ success: true, message: 'Strip diperbarui', data: updated });
};

// DELETE /api/sessions/:id -> hapus dari My Gallery
exports.remove = (req, res) => {
  if (!SessionModel.belongsToUser(req.params.id, DEFAULT_USER_ID)) {
    return res.status(404).json({ success: false, message: 'Strip tidak ditemukan' });
  }
  SessionModel.remove(req.params.id);
  res.json({ success: true, message: 'Strip dihapus dari galeri' });
};

// --- Nested: Photos dalam sebuah session ---

// POST /api/sessions/:id/photos -> tambah hasil jepretan Live Camera ke strip
exports.addPhoto = (req, res) => {
  if (!SessionModel.belongsToUser(req.params.id, DEFAULT_USER_ID)) {
    return res.status(404).json({ success: false, message: 'Strip tidak ditemukan' });
  }
  const photo = PhotoModel.create({ session_id: req.params.id, ...req.body });
  res.status(201).json({ success: true, message: 'Foto ditambahkan', data: photo });
};

// --- Nested: Decorations dalam sebuah session ---

// POST /api/sessions/:id/decorations -> Decorate Strip (tambah stiker/teks)
exports.addDecoration = (req, res) => {
  if (!SessionModel.belongsToUser(req.params.id, DEFAULT_USER_ID)) {
    return res.status(404).json({ success: false, message: 'Strip tidak ditemukan' });
  }
  const decoration = DecorationModel.create({ session_id: req.params.id, ...req.body });
  res.status(201).json({ success: true, message: 'Dekorasi ditambahkan', data: decoration });
};
