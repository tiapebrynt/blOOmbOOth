const FrameModel = require('../models/frameModel');

exports.getAll = (req, res) => {
  res.json({ success: true, data: FrameModel.findAll() });
};

exports.getOne = (req, res) => {
  const frame = FrameModel.findById(req.params.id);
  if (!frame) return res.status(404).json({ success: false, message: 'Frame tidak ditemukan' });
  res.json({ success: true, data: frame });
};

exports.create = (req, res) => {
  const { name, layout_type, thumbnail_path } = req.body;
  if (!name) return res.status(400).json({ success: false, message: 'Nama frame wajib diisi' });
  const frame = FrameModel.create({ name, layout_type, thumbnail_path });
  res.status(201).json({ success: true, message: 'Frame ditambahkan', data: frame });
};

exports.update = (req, res) => {
  const frame = FrameModel.findById(req.params.id);
  if (!frame) return res.status(404).json({ success: false, message: 'Frame tidak ditemukan' });
  const updated = FrameModel.update(req.params.id, req.body);
  res.json({ success: true, message: 'Frame diperbarui', data: updated });
};

exports.remove = (req, res) => {
  const frame = FrameModel.findById(req.params.id);
  if (!frame) return res.status(404).json({ success: false, message: 'Frame tidak ditemukan' });
  FrameModel.softDelete(req.params.id);
  res.json({ success: true, message: 'Frame dihapus' });
};
