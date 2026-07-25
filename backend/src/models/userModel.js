const db = require('../config/database');

const UserModel = {
  findById(id) {
    return db.prepare(`SELECT * FROM users WHERE id = ?`).get(id);
  },

  update(id, { name, avatar_path }) {
    db.prepare(
      `UPDATE users SET name = COALESCE(?, name), avatar_path = COALESCE(?, avatar_path), updated_at = datetime('now') WHERE id = ?`
    ).run(name, avatar_path, id);
    return this.findById(id);
  },

  toPublicJSON(user) {
    if (!user) return null;
    const { password, ...publicUser } = user;
    return publicUser;
  },
};

module.exports = UserModel;
