const FilterModel = require('../models/filterModel');

exports.getAll = (req, res) => {
  const { type } = req.query; // ?type=vibe_lighting
  res.json({ success: true, data: FilterModel.findAll(type) });
};

exports.getOne = (req, res) => {
  const filter = FilterModel.findById(req.params.id);
  if (!filter) return res.status(404).json({ success: false, message: 'Filter tidak ditemukan' });
  res.json({ success: true, data: filter });
};

exports.create = (req, res) => {
  const { name, type, thumbnail_path, intensity_default } = req.body;
  if (!name) return res.status(400).json({ success: false, message: 'Nama filter wajib diisi' });
  const filter = FilterModel.create({ name, type, thumbnail_path, intensity_default });
  res.status(201).json({ success: true, message: 'Filter ditambahkan', data: filter });
};

exports.update = (req, res) => {
  const filter = FilterModel.findById(req.params.id);
  if (!filter) return res.status(404).json({ success: false, message: 'Filter tidak ditemukan' });
  const updated = FilterModel.update(req.params.id, req.body);
  res.json({ success: true, message: 'Filter diperbarui', data: updated });
};

exports.remove = (req, res) => {
  const filter = FilterModel.findById(req.params.id);
  if (!filter) return res.status(404).json({ success: false, message: 'Filter tidak ditemukan' });
  FilterModel.remove(req.params.id);
  res.json({ success: true, message: 'Filter dihapus' });
};
