const UserModel = require('../models/userModel');
const { DEFAULT_USER_ID } = require('../config/constants');

// GET /api/profile -> tampilkan profil default user (App Settings screen)
exports.get = (req, res) => {
  const user = UserModel.findById(DEFAULT_USER_ID);
  res.json({ success: true, data: UserModel.toPublicJSON(user) });
};

// PUT /api/profile -> update nama/avatar default user
exports.update = (req, res) => {
  const { name, avatar_path } = req.body;
  const user = UserModel.update(DEFAULT_USER_ID, { name, avatar_path });
  res.json({ success: true, message: 'Profil diperbarui', data: UserModel.toPublicJSON(user) });
};
