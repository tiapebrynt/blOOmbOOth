# Photobooth Mobile App (Flutter)

Aplikasi mobile client untuk Photobooth, dibangun dengan Flutter dan mengonsumsi REST API dari folder `backend/`.

## 1. Instalasi

> Project ini dibuat sebagai kumpulan source code Dart (`lib/`) + `pubspec.yaml`. Karena environment pembuatan ZIP ini tidak memiliki Flutter SDK/akses ke pub.dev, folder platform (`android/`, `ios/`) **belum** di-generate. Jalankan langkah berikut di komputer kamu yang sudah terinstall Flutter:

```bash
cd mobile

# 1) Generate folder platform (android/ios/web) berdasarkan pubspec.yaml & lib/ yang sudah ada
flutter create . --project-name photobooth_app --org com.example

# 2) Install dependencies
flutter pub get

# 3) Jalankan
flutter run
```

`flutter create .` aman dijalankan di folder yang sudah berisi `lib/` dan `pubspec.yaml` — Flutter hanya akan menambahkan folder platform yang belum ada tanpa menimpa kode yang sudah ditulis.

## 2. Atur Base URL API

Edit `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
static const String storageUrl = 'http://10.0.2.2:3000';
```

| Skenario                         | `baseUrl`                                   |
|----------------------------------|-----------------------------------------------|
| Android Emulator ke backend lokal| `http://10.0.2.2:3000/api` (default)          |
| Device fisik (satu jaringan WiFi)| `http://<IP-LAPTOP-KAMU>:3000/api`            |
| Backend sudah di-hosting online  | `https://domain-kamu.com/api`                 |

## 3. Permission yang Perlu Ditambahkan

Setelah menjalankan `flutter create .`, tambahkan permission berikut agar fitur kamera & galeri berjalan:

**Android** — `android/app/src/main/AndroidManifest.xml` (di dalam tag `<manifest>`, sebelum `<application>`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Aplikasi membutuhkan akses kamera untuk fitur photobooth</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi membutuhkan akses galeri untuk memilih foto</string>
```

## 4. Struktur Folder

```
mobile/lib/
├── models/       # representasi 7 entitas backend (User, Frame, Filter, PhotoSession, Photo, Decoration, AppSettings)
├── services/      # pemanggil REST API per entitas (ApiClient sebagai wrapper http)
├── screens/       # 1 file per layar sesuai desain UI/UX
├── widgets/       # komponen reusable (button, loading/error state, countdown overlay)
├── utils/         # constants, theme, token storage, booth draft (state sementara alur capture)
└── main.dart       # entrypoint
```

## 5. Pemetaan Layar ke Fitur

| Layar (sesuai desain)  | File                             | Fungsi CRUD                                   |
|--------------------------|-----------------------------------|--------------------------------------------------|
| Live Camera              | `live_camera_screen.dart`        | Capture foto (kamera device) + countdown         |
| Countdown                | `widgets/countdown_overlay.dart` | Overlay hitung mundur sebelum jepret              |
| Live Effects              | `live_effects_screen.dart`       | Pilih preset efek real-time                       |
| Frame Selection           | `frame_selection_screen.dart`    | **Read** daftar frame dari API                    |
| Filter Library            | `filter_library_screen.dart`     | **Read** daftar filter warna dari API             |
| Vibe Lighting              | `vibe_lighting_screen.dart`       | **Read** filter vibe lighting + slider intensitas  |
| Beauty Enhancement          | `beauty_enhancement_screen.dart` | Atur smoothing/brighten (dikirim saat simpan)     |
| Final Preview                | `final_preview_screen.dart`      | **Create** strip baru + upload foto ke backend    |
| My Gallery                    | `my_gallery_screen.dart`          | **Read** semua strip tersimpan, search             |
| Strip Detail                    | `strip_detail_screen.dart`        | **Read** detail, **Update** judul/favorit, **Delete** |
| Decorate Strip                    | `decorate_strip_screen.dart`      | **Create/Update/Delete** dekorasi (stiker/teks)   |
| App Settings                        | `app_settings_screen.dart`        | **Read/Update** profil & preferensi user           |

> Aplikasi ini tidak memiliki layar Login/Register — begitu dibuka, aplikasi langsung menampilkan Splash Screen singkat lalu masuk ke halaman utama (Booth/Gallery/Settings).

## 6. Alur Penggunaan Aplikasi

1. Buka aplikasi → Splash Screen singkat → langsung masuk ke halaman utama (tidak ada login/register).
2. Tab **Booth** → `Live Camera` → jepret sejumlah foto sesuai layout → `Frame Selection` → `Filter Library` → `Vibe Lighting` → `Beauty Enhancement` → `Final Preview`.
3. Di **Final Preview**, tekan "Simpan ke My Gallery" → tiap foto di-upload ke `/api/uploads`, lalu strip dibuat via `POST /api/sessions`.
4. Tab **My Gallery** menampilkan seluruh strip tersimpan → tap salah satu → **Strip Detail** → bisa ubah judul, tandai favorit, hapus, atau lanjut ke **Decorate Strip** untuk menambah stiker/teks.
5. Tab **Settings** menampilkan profil & preferensi (resolusi kamera, watermark, durasi countdown, live effects).
