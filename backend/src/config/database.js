const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dbDir = path.join(__dirname, '..', '..', 'database');
if (!fs.existsSync(dbDir)) fs.mkdirSync(dbDir, { recursive: true });

const dbPath = path.join(dbDir, 'photobooth.sqlite');
const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ---------------------------------------------------------------------
// SCHEMA
// 7 tabel dengan relasi (bukan tabel tunggal):
//   users (1) ----< photo_sessions (N)
//   users (1) ----(1) app_settings
//   frames (1) ----< photo_sessions (N)
//   photo_sessions (1) ----< photos (N)
//   photo_sessions (1) ----< decorations (N)
//   filters (1) ----< photos (N)
// ---------------------------------------------------------------------
db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  avatar_path TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS frames (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  layout_type TEXT NOT NULL DEFAULT '4-cut',
  thumbnail_path TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS filters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'color',      -- color | vibe_lighting | beauty
  thumbnail_path TEXT,
  intensity_default REAL NOT NULL DEFAULT 0.5,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS photo_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  frame_id INTEGER,
  title TEXT NOT NULL DEFAULT 'Untitled Strip',
  layout_type TEXT NOT NULL DEFAULT '4-cut',
  is_favorite INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (frame_id) REFERENCES frames(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  filter_id INTEGER,
  image_path TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  beauty_smooth REAL NOT NULL DEFAULT 0,
  beauty_brighten REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (session_id) REFERENCES photo_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (filter_id) REFERENCES filters(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS decorations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  type TEXT NOT NULL DEFAULT 'sticker',   -- sticker | text | emoji
  content TEXT NOT NULL,
  pos_x REAL NOT NULL DEFAULT 0,
  pos_y REAL NOT NULL DEFAULT 0,
  scale REAL NOT NULL DEFAULT 1,
  rotation REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (session_id) REFERENCES photo_sessions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS app_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL UNIQUE,
  camera_resolution TEXT NOT NULL DEFAULT '1080p',
  watermark_enabled INTEGER NOT NULL DEFAULT 1,
  countdown_duration INTEGER NOT NULL DEFAULT 3,
  live_effects_enabled INTEGER NOT NULL DEFAULT 1,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
`);

module.exports = db;
