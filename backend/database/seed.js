const db = require('../src/config/database');
const { DEFAULT_USER_ID } = require('../src/config/constants');

// Aplikasi tidak memakai login/register, tapi tabel `photo_sessions` dan
// `app_settings` tetap berelasi ke `users` lewat foreign key. Karena itu
// perlu ada 1 baris default user supaya relasi tersebut valid.
const existingUser = db.prepare(`SELECT id FROM users WHERE id = ?`).get(DEFAULT_USER_ID);
if (!existingUser) {
  db.prepare(
    `INSERT INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)`
  ).run(DEFAULT_USER_ID, 'Guest User', 'guest@photobooth.local', '-', 'user');
  console.log('Seeded default user (id=1)');
} else {
  console.log('Default user sudah ada, skip seeding');
}

const frames = [
  { name: 'Spring Bloom', layout_type: '4-cut', thumbnail_path: '/seed/frames/1.png' },
  { name: 'Golden Hour', layout_type: '4-cut', thumbnail_path: '/seed/frames/2.png' },
  { name: 'Cherry Blossom', layout_type: '4-cut', thumbnail_path: '/seed/frames/3.png' },
  { name: 'Pastel Dream', layout_type: '4-cut', thumbnail_path: '/seed/frames/4.png' },
  { name: 'Vintage Rose', layout_type: '4-cut', thumbnail_path: '/seed/frames/5.png' },
  { name: 'Ocean Breeze', layout_type: '4-cut', thumbnail_path: '/seed/frames/6.png' },
  { name: 'Sunflower', layout_type: '4-cut', thumbnail_path: '/seed/frames/7.png' },
  { name: 'Lavender', layout_type: '4-cut', thumbnail_path: '/seed/frames/8.png' },
  { name: 'Starry Night', layout_type: '4-cut', thumbnail_path: '/seed/frames/9.png' },
  { name: 'Tropical Paradise', layout_type: '4-cut', thumbnail_path: '/seed/frames/10.png' },
  { name: 'Rainbow', layout_type: '4-cut', thumbnail_path: '/seed/frames/11.png' },
  { name: 'Classic Strip', layout_type: '4-cut', thumbnail_path: '/seed/frames/12.png' },
];

const filters = [
  { name: 'Natural Glow', type: 'vibe_lighting', thumbnail_path: '/seed/filters/natural.png', intensity_default: 0.5 },
  { name: 'Warm Sunset', type: 'vibe_lighting', thumbnail_path: '/seed/filters/warm.png', intensity_default: 0.6 },
  { name: 'Cool Studio', type: 'vibe_lighting', thumbnail_path: '/seed/filters/cool.png', intensity_default: 0.4 },
  { name: 'Soft Skin', type: 'beauty', thumbnail_path: '/seed/filters/soft_skin.png', intensity_default: 0.5 },
  { name: 'Face Slim', type: 'beauty', thumbnail_path: '/seed/filters/face_slim.png', intensity_default: 0.3 },
  { name: 'Black & White', type: 'color', thumbnail_path: '/seed/filters/bw.png', intensity_default: 1.0 },
  { name: 'Vintage Film', type: 'color', thumbnail_path: '/seed/filters/vintage.png', intensity_default: 0.7 },
];

const insertFrame = db.prepare(
  `INSERT INTO frames (name, layout_type, thumbnail_path) VALUES (@name, @layout_type, @thumbnail_path)`
);
const insertFilter = db.prepare(
  `INSERT INTO filters (name, type, thumbnail_path, intensity_default) VALUES (@name, @type, @thumbnail_path, @intensity_default)`
);

const frameCount = db.prepare(`SELECT COUNT(*) AS c FROM frames`).get().c;
const filterCount = db.prepare(`SELECT COUNT(*) AS c FROM filters`).get().c;

const insertMany = db.transaction((rows, stmt) => {
  for (const row of rows) stmt.run(row);
});

if (frameCount === 0) {
  insertMany(frames, insertFrame);
  console.log(`Seeded ${frames.length} frames`);
} else {
  console.log('Frames sudah ada, skip seeding');
}

if (filterCount === 0) {
  insertMany(filters, insertFilter);
  console.log(`Seeded ${filters.length} filters`);
} else {
  console.log('Filters sudah ada, skip seeding');
}

console.log('✅ Seeding selesai');
