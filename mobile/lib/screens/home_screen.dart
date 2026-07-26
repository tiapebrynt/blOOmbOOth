// Mengimpor package Material Design Flutter
// Berisi widget-widget dasar seperti Scaffold, Text, Icon, Button, Navigator, dll.
import 'package:flutter/material.dart';

// Mengimpor file theme.dart
// Digunakan untuk mengambil warna dan tema aplikasi,
// misalnya AppColors.primary agar warna tetap konsisten.
import '../utils/theme.dart';

// Mengimpor model BoothDraft.
// BoothDraft berfungsi sebagai tempat penyimpanan sementara (draft)
// data yang akan digunakan selama proses photobooth,
// seperti frame yang dipilih, hasil foto, filter, dan data lainnya.
import '../utils/booth_draft.dart';

// Mengimpor halaman FrameSelectionScreen.
// Halaman ini akan ditampilkan setelah pengguna menekan tombol
// "Start Photobooth".
import 'frame_selection_screen.dart';

// HomeScreen merupakan halaman pertama (landing page)
// yang akan dilihat pengguna ketika aplikasi dibuka.
class HomeScreen extends StatelessWidget {
  // Constructor const digunakan karena widget ini tidak memiliki state
  // sehingga lebih efisien saat proses rendering.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold merupakan kerangka utama halaman
    // yang menyediakan struktur seperti background, body, appBar, dll.
    return Scaffold(

      // Mengatur warna latar belakang halaman menjadi putih.
      backgroundColor: Colors.white,

      // Body berisi seluruh isi halaman.
      body: Center(

        // Container digunakan untuk membatasi lebar tampilan
        // agar tetap nyaman ketika dijalankan pada tablet maupun desktop.
        child: Container(

          // Maksimal lebar tampilan adalah 480 pixel.
          constraints: const BoxConstraints(maxWidth: 480),

          // Memberikan jarak di dalam container.
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 24.0,
          ),

          // Column digunakan untuk menyusun widget secara vertikal.
          child: Column(

            // Seluruh isi berada di tengah layar secara vertikal.
            mainAxisAlignment: MainAxisAlignment.center,

            // Seluruh widget memenuhi lebar container.
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              // ============================================================
              // Logo Aplikasi
              // ============================================================

              const Center(
                child: Padding(

                  // Memberikan jarak di sekitar logo.
                  padding: EdgeInsets.all(24),

                  // Menampilkan icon kamera sebagai logo aplikasi.
                  child: Icon(
                    Icons.photo_camera_back_rounded,

                    // Ukuran icon.
                    size: 80,

                    // Menggunakan warna utama aplikasi.
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Memberikan jarak setelah logo.
              const SizedBox(height: 32),

              // ============================================================
              // Judul Aplikasi
              // ============================================================

              const Text(
                "BloomBooth",

                // Teks berada di tengah.
                textAlign: TextAlign.center,

                style: TextStyle(

                  // Ukuran huruf.
                  fontSize: 36,

                  // Huruf dibuat tebal.
                  fontWeight: FontWeight.bold,

                  // Memberikan sedikit jarak antar huruf.
                  letterSpacing: 0.5,

                  // Warna teks.
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // ============================================================
              // Subjudul / Deskripsi
              // ============================================================

              const Text(
                "Capture your beautiful moments instantly",

                // Posisi teks di tengah.
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              // Memberikan jarak sebelum tombol.
              const SizedBox(height: 64),

              // ============================================================
              // Tombol Start Photobooth
              // ============================================================

              ElevatedButton(

                // Fungsi yang dijalankan ketika tombol ditekan.
                onPressed: () {

                  // Navigator digunakan untuk berpindah halaman.
                  Navigator.of(context).push(

                    // MaterialPageRoute memberikan efek transisi
                    // standar Android ketika berpindah halaman.
                    MaterialPageRoute(

                      // Builder menentukan halaman tujuan.
                      builder: (_) =>

                          // Membuka halaman FrameSelectionScreen.
                          //
                          // Parameter draft wajib dikirimkan.
                          // BoothDraft() membuat objek draft baru
                          // yang nantinya akan menyimpan seluruh data
                          // selama proses photobooth berlangsung.
                          FrameSelectionScreen(
                            draft: BoothDraft(),
                          ),
                    ),
                  );
                },

                // Mengatur tampilan tombol.
                style: ElevatedButton.styleFrom(

                  // Warna background tombol.
                  backgroundColor: AppColors.primary,

                  // Warna tulisan dan icon.
                  foregroundColor: Colors.white,

                  // Padding bagian dalam tombol.
                  padding: const EdgeInsets.symmetric(vertical: 20),

                  // Efek bayangan tombol.
                  elevation: 3,

                  // Membuat sudut tombol melengkung.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Isi tombol.
                child: const Row(

                  // Posisi isi tombol berada di tengah.
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    // Icon play.
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 28,
                    ),

                    // Memberikan jarak antara icon dan teks.
                    SizedBox(width: 8),

                    // Tulisan pada tombol.
                    Text(
                      "Start Photobooth",

                      style: TextStyle(

                        // Ukuran teks.
                        fontSize: 18,

                        // Huruf dibuat tebal.
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}