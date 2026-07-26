// Mengimpor package Material Design Flutter.
// Package ini menyediakan berbagai widget bawaan Flutter
// seperti Scaffold, Text, Icon, Navigator, Container, dan lain-lain.
import 'package:flutter/material.dart';

// Mengimpor class BoothDraft.
// BoothDraft digunakan sebagai penyimpanan sementara (draft)
// untuk data sesi photobooth yang sedang berlangsung,
// seperti frame yang dipilih, hasil foto, filter, dan data lainnya.
import '../utils/booth_draft.dart';

// Mengimpor file theme.dart.
// Berisi kumpulan warna, gradient, dan tema aplikasi
// agar tampilan aplikasi tetap konsisten.
import '../utils/theme.dart';

// Mengimpor widget PrimaryButton.
// Widget ini merupakan tombol kustom yang digunakan
// agar desain tombol pada seluruh aplikasi memiliki tampilan yang sama.
import '../widgets/primary_button.dart';

// Mengimpor halaman FrameSelectionScreen.
// Halaman ini akan ditampilkan setelah pengguna
// menekan tombol "Start Photobooth".
import 'frame_selection_screen.dart';

/// ======================================================================
/// BoothHomeScreen
/// ======================================================================
///
/// Halaman ini merupakan halaman utama (Home) pada fitur Photobooth.
///
/// Fungsi halaman ini adalah sebagai titik awal pengguna sebelum
/// memulai sesi photobooth.
///
/// Alur yang terjadi pada halaman ini:
/// 1. Pengguna membuka BoothHomeScreen.
/// 2. Menekan tombol "Start Photobooth".
/// 3. Sistem membuat objek BoothDraft baru.
/// 4. Pengguna diarahkan ke halaman FrameSelectionScreen
///    untuk memilih frame photobooth.
class BoothHomeScreen extends StatelessWidget {

  // Constructor const digunakan karena widget ini bersifat statis
  // (tidak memiliki state yang berubah selama aplikasi berjalan).
  const BoothHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // Scaffold merupakan kerangka utama sebuah halaman Flutter.
    // Scaffold menyediakan area body, appBar, floatingActionButton,
    // bottomNavigationBar, dan komponen layout lainnya.
    return Scaffold(

      // Body merupakan isi utama dari halaman.
      body: Container(

        // Memberikan dekorasi berupa background gradient
        // menggunakan warna yang telah didefinisikan pada AppColors.
        decoration: const BoxDecoration(
          gradient: AppColors.gradient,
        ),

        // SafeArea digunakan agar isi halaman tidak tertutup
        // oleh status bar, notch, maupun navigation bar perangkat.
        child: SafeArea(

          // Memberikan jarak (padding) pada seluruh isi halaman.
          child: Padding(
            padding: const EdgeInsets.all(24),

            // Column digunakan untuk menyusun widget secara vertikal.
            child: Column(

              // Seluruh isi ditempatkan di tengah halaman secara vertikal.
              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                // ==========================================================
                // Icon Photobooth
                // ==========================================================

                // Menampilkan icon kamera sebagai ilustrasi
                // bahwa halaman ini merupakan fitur photobooth.
                const Icon(
                  Icons.camera_alt_rounded,

                  // Ukuran icon.
                  size: 80,

                  // Menggunakan warna utama aplikasi.
                  color: AppColors.primary,
                ),

                // Memberikan jarak antara icon dan judul.
                const SizedBox(height: 16),

                // ==========================================================
                // Judul Halaman
                // ==========================================================

                const Text(
                  'Photobooth',

                  style: TextStyle(

                    // Ukuran teks.
                    fontSize: 26,

                    // Huruf dibuat tebal.
                    fontWeight: FontWeight.bold,

                    // Menggunakan warna teks utama.
                    color: AppColors.textDark,
                  ),
                ),

                // Memberikan jarak antara judul dan deskripsi.
                const SizedBox(height: 8),

                // ==========================================================
                // Deskripsi Halaman
                // ==========================================================

                const Text(
                  'Ambil foto strip favoritmu dengan filter, effect, dan vibe kece.',

                  // Posisi teks berada di tengah.
                  textAlign: TextAlign.center,

                  style: TextStyle(

                    // Menggunakan warna teks sekunder.
                    color: AppColors.textMuted,
                  ),
                ),

                // Memberikan jarak sebelum tombol.
                const SizedBox(height: 32),

                // ==========================================================
                // Tombol Start Photobooth
                // ==========================================================

                // Menggunakan widget PrimaryButton
                // agar tampilan tombol konsisten dengan halaman lain.
                PrimaryButton(

                  // Tulisan yang ditampilkan pada tombol.
                  label: 'Start Photobooth',

                  // Icon yang ditampilkan pada tombol.
                  icon: Icons.play_arrow_rounded,

                  // Fungsi yang dijalankan ketika tombol ditekan.
                  onPressed: () {

                    // Membuat objek BoothDraft baru.
                    //
                    // Setiap kali pengguna memulai sesi photobooth,
                    // sistem akan membuat draft baru agar data sesi
                    // sebelumnya tidak tercampur dengan sesi berikutnya.
                    final draft = BoothDraft();

                    // Navigator digunakan untuk berpindah halaman.
                    Navigator.of(context).push(

                      // MaterialPageRoute memberikan animasi perpindahan
                      // halaman standar Android.
                      MaterialPageRoute(

                        // Halaman tujuan adalah FrameSelectionScreen.
                        //
                        // Objek BoothDraft dikirim sebagai parameter
                        // agar data sesi dapat digunakan pada halaman
                        // pemilihan frame dan proses selanjutnya.
                        builder: (_) =>
                            FrameSelectionScreen(
                              draft: draft,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}