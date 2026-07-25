const { DEFAULT_USER_ID } = require('../config/constants');
const SettingsModel = require('../models/settingsModel');

// GET /api/settings -> App Settings screen (camera resolution, watermark, countdown, dll)
exports.get = (req, res) => {
  const settings = SettingsModel.findByUser(DEFAULT_USER_ID);
  res.json({ success: true, data: settings });
};

// PUT /api/settings -> update preferensi user
exports.update = (req, res) => {
  const settings = SettingsModel.update(DEFAULT_USER_ID, req.body);
  res.json({ success: true, message: 'Pengaturan diperbarui', data: settings });
};
