const db = require('../config/database');

const SettingsModel = {
  findByUser(user_id) {
    let row = db.prepare(`SELECT * FROM app_settings WHERE user_id = ?`).get(user_id);
    if (!row) {
      // auto-create default settings row on first access
      db.prepare(`INSERT INTO app_settings (user_id) VALUES (?)`).run(user_id);
      row = db.prepare(`SELECT * FROM app_settings WHERE user_id = ?`).get(user_id);
    }
    return row;
  },

  update(
    user_id,
    { camera_resolution, watermark_enabled, countdown_duration, live_effects_enabled }
  ) {
    this.findByUser(user_id); // ensure row exists
    db.prepare(
      `UPDATE app_settings SET
        camera_resolution = COALESCE(?, camera_resolution),
        watermark_enabled = COALESCE(?, watermark_enabled),
        countdown_duration = COALESCE(?, countdown_duration),
        live_effects_enabled = COALESCE(?, live_effects_enabled),
        updated_at = datetime('now')
       WHERE user_id = ?`
    ).run(camera_resolution, watermark_enabled, countdown_duration, live_effects_enabled, user_id);
    return this.findByUser(user_id);
  },
};

module.exports = SettingsModel;
