const db = require('../config/database');

const DecorationModel = {
  create({ session_id, type, content, pos_x, pos_y, scale, rotation }) {
    const info = db
      .prepare(
        `INSERT INTO decorations (session_id, type, content, pos_x, pos_y, scale, rotation)
         VALUES (?, ?, ?, ?, ?, ?, ?)`
      )
      .run(
        session_id,
        type || 'sticker',
        content,
        pos_x ?? 0,
        pos_y ?? 0,
        scale ?? 1,
        rotation ?? 0
      );
    return this.findById(info.lastInsertRowid);
  },

  findById(id) {
    return db.prepare(`SELECT * FROM decorations WHERE id = ?`).get(id);
  },

  findBySession(session_id) {
    return db.prepare(`SELECT * FROM decorations WHERE session_id = ?`).all(session_id);
  },

  update(id, { pos_x, pos_y, scale, rotation, content }) {
    db.prepare(
      `UPDATE decorations SET
        pos_x = COALESCE(?, pos_x),
        pos_y = COALESCE(?, pos_y),
        scale = COALESCE(?, scale),
        rotation = COALESCE(?, rotation),
        content = COALESCE(?, content)
       WHERE id = ?`
    ).run(pos_x, pos_y, scale, rotation, content, id);
    return this.findById(id);
  },

  remove(id) {
    db.prepare(`DELETE FROM decorations WHERE id = ?`).run(id);
    return true;
  },
};

module.exports = DecorationModel;
