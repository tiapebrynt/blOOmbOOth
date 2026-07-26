// Mengimpor package Material Design Flutter.
// Package ini menyediakan berbagai widget bawaan Flutter
// seperti Scaffold, AppBar, GridView, Navigator, FloatingActionButton, dll.
import 'package:flutter/material.dart';

// Mengimpor model FrameModel.
// Model ini digunakan untuk merepresentasikan data sebuah frame,
// seperti id, nama frame, dan informasi lainnya.
import '../models/frame_model.dart';

// Mengimpor FrameService.
// Service ini bertugas mengambil data frame,
// misalnya dari database, API, atau data lokal aplikasi.
import '../services/frame_service.dart';

// Mengimpor BoothDraft.
// BoothDraft digunakan untuk menyimpan data sementara
// selama proses photobooth berlangsung.
import '../utils/booth_draft.dart';

// Mengimpor file tema aplikasi.
// Berisi warna, gradient, dan style yang digunakan
// agar tampilan aplikasi tetap konsisten.
import '../utils/theme.dart';

// Mengimpor widget LoadingView dan EmptyView.
// Widget ini digunakan untuk menampilkan tampilan
// ketika data sedang dimuat atau ketika data kosong.
import '../widgets/state_views.dart';

// Mengimpor halaman LiveCameraScreen.
// Halaman ini akan dibuka setelah pengguna memilih frame.
import 'live_camera_screen.dart';

/// ======================================================================
/// Konstanta Jumlah Slot Foto
/// ======================================================================
///
/// Menentukan jumlah slot foto default yang digunakan
/// pada setiap frame photobooth.
///
/// Saat ini seluruh frame memiliki 3 slot foto.
const int defaultSlotCount = 3;

/// ======================================================================
/// FrameSelectionScreen
/// ======================================================================
///
/// Halaman ini digunakan untuk menampilkan seluruh pilihan frame
/// yang dapat dipilih oleh pengguna sebelum memulai sesi photobooth.
///
/// Alur halaman:
/// 1. Mengambil daftar frame menggunakan FrameService.
/// 2. Menampilkan seluruh frame dalam bentuk Grid.
/// 3. Pengguna memilih salah satu frame.
/// 4. Tombol konfirmasi muncul.
/// 5. Pengguna diarahkan ke halaman LiveCameraScreen.
class FrameSelectionScreen extends StatefulWidget {

  /// Menyimpan objek BoothDraft yang dikirim dari halaman sebelumnya.
  final BoothDraft draft;

  // Constructor.
  const FrameSelectionScreen({
    super.key,
    required this.draft,
  });

  @override
  State<FrameSelectionScreen> createState() =>
      _FrameSelectionScreenState();
}

class _FrameSelectionScreenState
    extends State<FrameSelectionScreen> {

  /// Menyimpan seluruh data frame yang berhasil dimuat.
  List<FrameModel> _frames = [];

  /// Menentukan apakah data sedang dimuat atau tidak.
  bool _isLoading = true;

  /// Menyimpan id frame yang dipilih pengguna.
  int? _selectedId;

  @override
  void initState() {
    super.initState();

    // Dipanggil pertama kali ketika halaman dibuat.
    // Berfungsi untuk mengambil daftar frame.
    _loadFrames();
  }

  /// ==================================================================
  /// Mengambil Data Frame
  /// ==================================================================
  ///
  /// Fungsi asynchronous yang mengambil seluruh data frame
  /// melalui FrameService.
  Future<void> _loadFrames() async {

    // Menampilkan loading.
    setState(() => _isLoading = true);

    try {

      // Mengambil seluruh data frame.
      final data = await FrameService.getAll();

      // Mengecek apakah widget masih aktif.
      if (mounted) {

        // Menyimpan data frame ke dalam list.
        setState(() => _frames = data);
      }

    } catch (e) {

      // Jika terjadi error,
      // tampilkan pesan menggunakan SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat frame: $e',
            ),
          ),
        );
      }

    } finally {

      // Setelah proses selesai,
      // loading dinonaktifkan.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Scaffold merupakan struktur utama halaman.
    return Scaffold(

      // AppBar yang ditampilkan di bagian atas halaman.
      appBar: AppBar(
        title: const Text("Pilih Frame"),
      ),

      // ==============================================================
      // Body Halaman
      // ==============================================================

      body: _isLoading

          // Jika data sedang dimuat,
          // tampilkan LoadingView.
          ? const LoadingView()

          // Jika data kosong,
          // tampilkan EmptyView.
          : _frames.isEmpty
              ? const EmptyView(
                  message: 'Tidak ada frame tersedia',
                  icon: Icons.style,
                )

              // Jika data tersedia,
              // tampilkan GridView.
              : GridView.builder(

                  // Padding seluruh grid.
                  padding: const EdgeInsets.all(16),

                  // Mengatur jumlah kolom dan jarak antar item.
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(

                    // Jumlah kolom.
                    crossAxisCount: 3,

                    // Jarak horizontal.
                    crossAxisSpacing: 10,

                    // Jarak vertikal.
                    mainAxisSpacing: 10,
                  ),

                  // Jumlah item.
                  itemCount: _frames.length,

                  // Membangun setiap item frame.
                  itemBuilder: (ctx, i) {

                    // Mengambil data frame berdasarkan index.
                    final frame = _frames[i];

                    // Mengambil id frame.
                    final id = frame.id;

                    // GestureDetector digunakan
                    // agar item dapat ditekan.
                    return GestureDetector(

                      // Ketika frame dipilih,
                      // simpan id frame tersebut.
                      onTap: () =>
                          setState(() => _selectedId = id),

                      child: Container(

                        // Dekorasi kotak frame.
                        decoration: BoxDecoration(

                          // Border berubah warna ketika dipilih.
                          border: Border.all(
                            color: _selectedId == id
                                ? Colors.blue
                                : Colors.grey,

                            width: _selectedId == id
                                ? 3
                                : 1,
                          ),

                          borderRadius:
                              BorderRadius.circular(8),
                        ),

                        child: Column(
                          children: [

                            // ==================================================
                            // Preview Frame
                            // ==================================================

                            Expanded(
                              child: ClipRRect(

                                // Membuat sudut gambar melengkung.
                                borderRadius:
                                    BorderRadius.circular(6),

                                child: Image.asset(

                                  // Mengambil gambar frame
                                  // berdasarkan id.
                                  'assets/frames/$id.png',

                                  fit: BoxFit.cover,

                                  // Jika gambar tidak ditemukan,
                                  // tampilkan icon broken image.
                                  errorBuilder:
                                      (_, __, ___) =>
                                          Container(

                                    color: AppColors.secondary
                                        .withOpacity(0.15),

                                    child: const Icon(
                                      Icons.broken_image,
                                      color:
                                          AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ==================================================
                            // Nama Frame
                            // ==================================================

                            Container(

                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 4,
                              ),

                              color: Colors.black54,

                              width: double.infinity,

                              child: Text(

                                // Nama frame.
                                frame.name,

                                textAlign:
                                    TextAlign.center,

                                maxLines: 1,

                                overflow:
                                    TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

      // ==============================================================
      // Floating Action Button
      // ==============================================================

      floatingActionButton:

          // Jika belum memilih frame,
          // tombol tidak ditampilkan.
          _selectedId == null
              ? null

              // Jika frame sudah dipilih,
              // tampilkan tombol konfirmasi.
              : FloatingActionButton(

                  // Fungsi ketika tombol ditekan.
                  onPressed: () {

                    // Berpindah ke halaman kamera.
                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            LiveCameraScreen(

                          // Jumlah foto yang harus diambil.
                          shotCount: defaultSlotCount,

                          // Mengirim id frame
                          // yang telah dipilih.
                          frameId:
                              _selectedId.toString(),
                        ),
                      ),
                    );
                  },

                  // Icon tombol.
                  child: const Icon(Icons.check),
                ),
    );
  }
}