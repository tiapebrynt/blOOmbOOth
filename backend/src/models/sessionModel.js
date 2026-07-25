const db = require('../config/database');

const SessionModel = {
  create({ user_id, frame_id, title, layout_type }) {
    const info = db
      .prepare(
        `INSERT INTO photo_sessions (user_id, frame_id, title, layout_type) VALUES (?, ?, ?, ?)`
      )
      .run(user_id, frame_id || null, title || 'Untitled Strip', layout_type || '4-cut');
    return this.findById(info.lastInsertRowid);
  },

  findAllByUser(user_id) {
    const sessions = db
      .prepare(
        `SELECT ps.*, f.name AS frame_name, f.thumbnail_path AS frame_thumbnail,
                (SELECT p.image_path FROM photos p WHERE p.session_id = ps.id ORDER BY p.order_index ASC LIMIT 1) AS first_photo_path
         FROM photo_sessions ps
         LEFT JOIN frames f ON f.id = ps.frame_id
         WHERE ps.user_id = ?
         ORDER BY ps.created_at DESC`
      )
      .all(user_id);

    // Attach photos to each session
    for (const session of sessions) {
      session.photos = db
        .prepare(
          `SELECT p.*, fl.name AS filter_name, fl.type AS filter_type
           FROM photos p
           LEFT JOIN filters fl ON fl.id = p.filter_id
           WHERE p.session_id = ?
           ORDER BY p.order_index ASC`
        )
        .all(session.id);
    }

    return sessions;
  },

  findById(id) {
    return db
      .prepare(
        `SELECT ps.*, f.name AS frame_name, f.thumbnail_path AS frame_thumbnail,
                (SELECT p.image_path FROM photos p WHERE p.session_id = ps.id ORDER BY p.order_index ASC LIMIT 1) AS first_photo_path
         FROM photo_sessions ps
         LEFT JOIN frames f ON f.id = ps.frame_id
         WHERE ps.id = ?`
      )
      .get(id);
  },

  // Strip Detail: session + all its photos (with filter info) + decorations
  findDetailById(id) {
    const session = this.findById(id);
    if (!session) return null;

    const photos = db
      .prepare(
        `SELECT p.*, fl.name AS filter_name, fl.type AS filter_type
         FROM photos p
         LEFT JOIN filters fl ON fl.id = p.filter_id
         WHERE p.session_id = ?
         ORDER BY p.order_index ASC`
      )
      .all(id);

    const decorations = db
      .prepare(`SELECT * FROM decorations WHERE session_id = ? ORDER BY id ASC`)
      .all(id);

    return { ...session, photos, decorations };
  },

  update(id, { title, frame_id, is_favorite }) {
    db.prepare(
      `UPDATE photo_sessions SET
        title = COALESCE(?, title),
        frame_id = COALESCE(?, frame_id),
        is_favorite = COALESCE(?, is_favorite),
        updated_at = datetime('now')
       WHERE id = ?`
    ).run(title, frame_id, is_favorite, id);
    return this.findById(id);
  },

  remove(id) {
    db.prepare(`DELETE FROM photo_sessions WHERE id = ?`).run(id);
    return true;
  },

  belongsToUser(id, user_id) {
    const row = db
      .prepare(`SELECT id FROM photo_sessions WHERE id = ? AND user_id = ?`)
      .get(id, user_id);
    return !!row;
  },
};

module.exports = SessionModel;
