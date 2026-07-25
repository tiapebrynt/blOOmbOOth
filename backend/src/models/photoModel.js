const db = require('../config/database');

const PhotoModel = {
  create({ session_id, filter_id, image_path, order_index, beauty_smooth, beauty_brighten }) {
    const info = db
      .prepare(
        `INSERT INTO photos (session_id, filter_id, image_path, order_index, beauty_smooth, beauty_brighten)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .run(
        session_id,
        filter_id || null,
        image_path,
        order_index ?? 0,
        beauty_smooth ?? 0,
        beauty_brighten ?? 0
      );
    return this.findById(info.lastInsertRowid);
  },

  findById(id) {
    return db.prepare(`SELECT * FROM photos WHERE id = ?`).get(id);
  },

  findBySession(session_id) {
    return db
      .prepare(`SELECT * FROM photos WHERE session_id = ? ORDER BY order_index ASC`)
      .all(session_id);
  },

  update(id, { filter_id, order_index, beauty_smooth, beauty_brighten }) {
    db.prepare(
      `UPDATE photos SET
        filter_id = COALESCE(?, filter_id),
        order_index = COALESCE(?, order_index),
        beauty_smooth = COALESCE(?, beauty_smooth),
        beauty_brighten = COALESCE(?, beauty_brighten)
       WHERE id = ?`
    ).run(filter_id, order_index, beauty_smooth, beauty_brighten, id);
    return this.findById(id);
  },

  remove(id) {
    db.prepare(`DELETE FROM photos WHERE id = ?`).run(id);
    return true;
  },
};

module.exports = PhotoModel;
