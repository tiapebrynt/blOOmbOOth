const { DEFAULT_USER_ID } = require('../config/constants');
const DecorationModel = require('../models/decorationModel');
const SessionModel = require('../models/sessionModel');

function assertOwnership(req, res) {
  const decoration = DecorationModel.findById(req.params.id);
  if (!decoration) {
    res.status(404).json({ success: false, message: 'Dekorasi tidak ditemukan' });
    return null;
  }
  if (!SessionModel.belongsToUser(decoration.session_id, DEFAULT_USER_ID)) {
    res.status(403).json({ success: false, message: 'Tidak memiliki akses ke dekorasi ini' });
    return null;
  }
  return decoration;
}

// PUT /api/decorations/:id -> geser posisi / ganti stiker (drag & drop di Decorate Strip)
exports.update = (req, res) => {
  const decoration = assertOwnership(req, res);
  if (!decoration) return;
  const updated = DecorationModel.update(req.params.id, req.body);
  res.json({ success: true, message: 'Dekorasi diperbarui', data: updated });
};

// DELETE /api/decorations/:id
exports.remove = (req, res) => {
  const decoration = assertOwnership(req, res);
  if (!decoration) return;
  DecorationModel.remove(req.params.id);
  res.json({ success: true, message: 'Dekorasi dihapus' });
};
