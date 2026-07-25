const db = require('../config/database');

const FrameModel = {
  findAll() {
    return db.prepare(`SELECT * FROM frames WHERE is_active = 1 ORDER BY id DESC`).all();
  },

  findById(id) {
    return db.prepare(`SELECT * FROM frames WHERE id = ?`).get(id);
  },

  create({ name, layout_type, thumbnail_path }) {
    const info = db
      .prepare(`INSERT INTO frames (name, layout_type, thumbnail_path) VALUES (?, ?, ?)`)
      .run(name, layout_type || '4-cut', thumbnail_path || null);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, layout_type, thumbnail_path }) {
    db.prepare(
      `UPDATE frames SET name = COALESCE(?, name), layout_type = COALESCE(?, layout_type), thumbnail_path = COALESCE(?, thumbnail_path) WHERE id = ?`
    ).run(name, layout_type, thumbnail_path, id);
    return this.findById(id);
  },

  softDelete(id) {
    db.prepare(`UPDATE frames SET is_active = 0 WHERE id = ?`).run(id);
    return true;
  },
};

module.exports = FrameModel;
