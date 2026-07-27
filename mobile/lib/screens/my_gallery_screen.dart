import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/photo_session_model.dart';
import '../models/photo_model.dart';
import '../services/session_service.dart';
import '../services/api_client.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/filter_data.dart';
import '../widgets/state_views.dart';
import 'gallery_detail_screen.dart';

// Koordinat slot foto (relatif terhadap ukuran container: x, y, width, height)
// dipakai untuk menempatkan 3 foto dalam layout strip vertikal.
final List<List<double>> _threeSlots = [
  [0.30, 0.193, 0.405, 0.193], // slot foto pertama (atas)
  [0.30, 0.403, 0.405, 0.193], // slot foto kedua (tengah)
  [0.30, 0.613, 0.405, 0.193], // slot foto ketiga (bawah)
];

// Mapping frameId -> daftar slot foto.
// Saat ini semua frame (1-12) memakai layout 3 slot yang sama (_threeSlots).
// Bisa dikembangkan nanti jika ada frame dengan jumlah/posisi slot berbeda.
final Map<int, List<List<double>>> _frameSlots = {
  1: _threeSlots, 2: _threeSlots, 3: _threeSlots,
  4: _threeSlots, 5: _threeSlots, 6: _threeSlots,
  7: _threeSlots, 8: _threeSlots, 9: _threeSlots,
  10: _threeSlots, 11: _threeSlots, 12: _threeSlots,
};

/// Halaman "My Gallery": menampilkan daftar strip foto yang tersimpan
/// dalam bentuk grid, lengkap dengan fitur pencarian, refresh, dan hapus.
class MyGalleryScreen extends StatefulWidget {
  const MyGalleryScreen({super.key});

  @override
  State<MyGalleryScreen> createState() => _MyGalleryScreenState();
}

class _MyGalleryScreenState extends State<MyGalleryScreen> {
  // Future yang menampung hasil fetch daftar sesi foto dari service.
  late Future<List<PhotoSessionModel>> _future;

  // Kata kunci pencarian (sudah di-lowercase) untuk filter judul strip.
  String _query = '';

  // Flag untuk menonaktifkan interaksi (tap/hapus) saat proses delete berjalan,
  // supaya user tidak bisa melakukan aksi ganda.
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Ambil data galeri pertama kali saat screen dibuka.
    _future = SessionService.getAll();
  }

  // Dipanggil oleh RefreshIndicator (pull-to-refresh) dan setelah aksi
  // tap/delete, untuk memuat ulang daftar sesi dari backend.
  Future<void> _refresh() async {
    setState(() => _future = SessionService.getAll());
  }

  // Menampilkan dialog konfirmasi sebelum menghapus strip.
  // Mengembalikan true jika user menekan "Hapus", false jika "Batal"/ditutup.
  Future<bool> _confirmDelete(PhotoSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Strip?'),
        content: Text('Apakah Anda yakin ingin menghapus\n"${session.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    // Jika dialog ditutup tanpa memilih (null), anggap sebagai "tidak jadi hapus".
    return confirmed ?? false;
  }

  // Proses penghapusan sesi foto:
  // 1. Minta konfirmasi user
  // 2. Panggil API hapus via SessionService
  // 3. Tampilkan snackbar sukses/gagal
  // 4. Refresh daftar galeri
  Future<void> _deleteSession(PhotoSessionModel session) async {
    final confirmed = await _confirmDelete(session);
    if (!confirmed) return; // Batal, tidak lakukan apa-apa

    setState(() => _isDeleting = true); // Kunci UI selama proses hapus
    try {
      await SessionService.remove(session.id);
      if (mounted) {
        // Notifikasi sukses hapus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Strip berhasil dihapus dari galeri'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
      _refresh(); // Reload data galeri setelah berhasil hapus
    } on ApiException catch (e) {
      // Tampilkan pesan error dari API jika request gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } finally {
      // Lepas kunci UI baik saat berhasil maupun gagal
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Judul halaman
            const Text('My Gallery',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),

            // Kolom pencarian, memfilter daftar sesi berdasarkan judul
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari strip...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // Daftar/grid strip foto dengan dukungan pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<PhotoSessionModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    // Selama data belum selesai dimuat, tampilkan loading state
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingView();
                    }
                    // Jika terjadi error saat fetch, tampilkan pesan error + tombol retry
                    if (snapshot.hasError) {
                      return ErrorView(
                        message: snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : 'Gagal memuat galeri. Periksa koneksi ke backend.',
                        onRetry: _refresh,
                      );
                    }

                    var sessions = snapshot.data ?? [];

                    // Terapkan filter pencarian berdasarkan judul strip (case-insensitive)
                    if (_query.isNotEmpty) {
                      sessions = sessions
                          .where((s) => s.title.toLowerCase().contains(_query))
                          .toList();
                    }

                    // Jika tidak ada data (kosong atau hasil filter kosong), tampilkan empty state
                    if (sessions.isEmpty) {
                      return const EmptyView(message: 'Belum ada strip tersimpan.\nYuk mulai photobooth!');
                    }

                    // Grid 2 kolom untuk menampilkan kartu-kartu galeri
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: sessions.length,
                      itemBuilder: (context, i) {
                        final session = sessions[i];
                        return _GalleryCard(
                          session: session,
                          isDeleting: _isDeleting,
                          onTap: () async {
                            try {
                              // Ambil detail lengkap sesi (termasuk semua foto) sebelum
                              // pindah ke halaman detail, karena data di grid mungkin
                              // hanya berupa ringkasan.
                              final fullSession = await SessionService.getOne(session.id);
                              if (!mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GalleryDetailScreen(session: fullSession),
                                ),
                              );
                            } on ApiException catch (e) {
                              // Gagal mengambil detail sesi, tampilkan pesan error
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
                                  ),
                                );
                              }
                            }
                            // Refresh galeri setelah kembali dari halaman detail
                            // (misalnya jika ada perubahan di layar detail).
                            _refresh();
                          },
                          onDelete: () => _deleteSession(session),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu galeri untuk satu sesi foto:
/// - Menampilkan preview mini photostrip dengan overlay frame
/// - Bisa di-tap untuk buka detail
/// - Bisa dihapus lewat swipe (Dismissible) atau tombol delete di pojok kanan atas
class _GalleryCard extends StatelessWidget {
  final PhotoSessionModel session;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _GalleryCard({
    required this.session,
    this.isDeleting = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Default ke frame 9 jika sesi tidak punya frameId.
    final frameId = session.frameId ?? 9;
    // Ambil layout slot sesuai frame, fallback ke frame 9 jika frameId tidak dikenal.
    final slots = _frameSlots[frameId] ?? _frameSlots[9]!;
    final photos = session.photos;
    // Jumlah foto yang dirender dibatasi oleh jumlah slot yang tersedia,
    // untuk menghindari index out of range.
    final photoCount = min(photos.length, slots.length);

    return GestureDetector(
      // Nonaktifkan tap saat sedang proses hapus
      onTap: isDeleting ? null : onTap,
      child: Dismissible(
        key: Key('gallery_${session.id}'),
        // Swipe dari kanan ke kiri untuk memicu aksi hapus
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        // Swipe tidak langsung menghapus item dari list (return false),
        // melainkan memicu onDelete() yang akan menampilkan dialog konfirmasi
        // dan me-refresh data setelah proses hapus selesai.
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bagian preview foto (thumbnail strip + frame overlay)
              Expanded(
                  child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Mini photostrip preview dengan frame overlay,
                        // hanya dirender jika ada foto tersedia.
                        if (photoCount > 0)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Ukuran container dipakai untuk mengonversi
                              // koordinat slot (0.0 - 1.0) menjadi posisi piksel.
                              final containerWidth = constraints.maxWidth;
                              final containerHeight = constraints.maxHeight;
                              return Stack(
                                children: [
                                  // Render tiap foto di posisi slot masing-masing
                                  ...List.generate(photoCount, (index) {
                                    final slot = slots[index];
                                    final photo = photos[index];
                                    return Positioned(
                                      left: slot[0] * containerWidth,
                                      top: slot[1] * containerHeight,
                                      width: slot[2] * containerWidth,
                                      height: slot[3] * containerHeight,
                                      child: _buildThumbnailPhoto(photo),
                                    );
                                  }),
                                  // Overlay gambar frame/bingkai di atas semua foto
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/frames/$frameId.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          // Tidak ada foto sama sekali -> tampilkan placeholder
                          _placeholder(),

                        // Tombol hapus mengambang di pojok kanan atas kartu
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: isDeleting ? null : onDelete,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bagian info: judul strip + tanggal dibuat
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(session.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  // Membangun widget thumbnail untuk satu foto dalam strip,
  // termasuk penerapan filter warna (jika foto punya filterName selain "Normal").
  Widget _buildThumbnailPhoto(PhotoModel photo) {
    Widget photoWidget = SizedBox.expand(
      child: ClipRect(
        child: Image.network(
          '${AppConstants.storageUrl}${photo.imagePath}',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          // Jika gambar gagal dimuat (mis. koneksi terputus / path salah),
          // tampilkan ikon broken image sebagai fallback.
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.secondary.withOpacity(0.15),
            child: const Icon(
              Icons.broken_image,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
        ),
      ),
    );

    final filterName = photo.filterName ?? 'Normal';

    // Terapkan color matrix filter (mis. sepia, hitam-putih, dll)
    // jika foto memiliki filter selain "Normal" dan filter tersebut dikenali.
    if (filterName != 'Normal' &&
        filterMatrices.containsKey(filterName)) {
      photoWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          filterMatrices[filterName]!,
        ),
        child: photoWidget,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: photoWidget,
    );
  }

  // Placeholder yang ditampilkan saat sesi belum/tidak punya foto.
  Widget _placeholder() => Container(
        color: AppColors.secondary.withOpacity(0.15),
        child: const Center(child: Icon(Icons.photo, color: AppColors.secondary, size: 40)),
      );
}

// Memformat tanggal mentah (string dari API) menjadi format "d MMM yyyy, HH:mm".
// Jika parsing gagal, fallback ke bagian pertama string sebelum spasi.
String _formatDate(String raw) {
  try {
    final date = DateTime.parse(raw);
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  } catch (_) {
    return raw.split(' ').first;
  }
}