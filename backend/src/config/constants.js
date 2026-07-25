// Aplikasi ini tidak lagi menggunakan login/register.
// Semua data (strip, foto, dekorasi, settings) tetap berelasi ke satu
// "default user" di tabel `users` supaya struktur relasi database (FK)
// tidak hilang, tanpa perlu autentikasi di sisi client.
module.exports = {
  DEFAULT_USER_ID: 1,
};
