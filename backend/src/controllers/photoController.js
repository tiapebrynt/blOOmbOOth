const { DEFAULT_USER_ID } = require('../config/constants');
const PhotoModel = require('../models/photoModel');
const SessionModel = require('../models/sessionModel');

function assertOwnership(req, res) {
  const photo = PhotoModel.findById(req.params.id);
  if (!photo) {
    res.status(404).json({ success: false, message: 'Foto tidak ditemukan' });
    return null;
  }
  if (!SessionModel.belongsToUser(photo.session_id, DEFAULT_USER_ID)) {
    res.status(403).json({ success: false, message: 'Tidak memiliki akses ke foto ini' });
    return null;
  }
  return photo;
}

// PUT /api/photos/:id -> ganti filter / urutan / beauty enhancement
exports.update = (req, res) => {
  const photo = assertOwnership(req, res);
  if (!photo) return;
  const updated = PhotoModel.update(req.params.id, req.body);
  res.json({ success: true, message: 'Foto diperbarui', data: updated });
};

// DELETE /api/photos/:id
exports.remove = (req, res) => {
  const photo = assertOwnership(req, res);
  if (!photo) return;
  PhotoModel.remove(req.params.id);
  res.json({ success: true, message: 'Foto dihapus' });
};
