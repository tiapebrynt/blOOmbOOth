const db = require('../config/database');

const FilterModel = {
  findAll(type) {
    if (type) {
      return db.prepare(`SELECT * FROM filters WHERE type = ? ORDER BY id`).all(type);
    }
    return db.prepare(`SELECT * FROM filters ORDER BY id`).all();
  },

  findById(id) {
    return db.prepare(`SELECT * FROM filters WHERE id = ?`).get(id);
  },

  create({ name, type, thumbnail_path, intensity_default }) {
    const info = db
      .prepare(
        `INSERT INTO filters (name, type, thumbnail_path, intensity_default) VALUES (?, ?, ?, ?)`
      )
      .run(name, type || 'color', thumbnail_path || null, intensity_default ?? 0.5);
    return this.findById(info.lastInsertRowid);
  },

  update(id, { name, type, thumbnail_path, intensity_default }) {
    db.prepare(
      `UPDATE filters SET name = COALESCE(?, name), type = COALESCE(?, type),
       thumbnail_path = COALESCE(?, thumbnail_path), intensity_default = COALESCE(?, intensity_default)
       WHERE id = ?`
    ).run(name, type, thumbnail_path, intensity_default, id);
    return this.findById(id);
  },

  remove(id) {
    db.prepare(`DELETE FROM filters WHERE id = ?`).run(id);
    return true;
  },
};

module.exports = FilterModel;
