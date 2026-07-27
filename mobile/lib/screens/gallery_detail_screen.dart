import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../models/photo_session_model.dart';
import '../models/photo_model.dart';
import '../models/history_model.dart';
import '../models/frame_model.dart';
import '../services/session_service.dart';
import '../services/frame_service.dart';
import '../services/api_client.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/filter_data.dart';
import '../widgets/state_views.dart';

// Koordinat slot foto (relatif terhadap ukuran container: x, y, width, height)
// dipakai untuk menempatkan 3 foto dalam layout strip vertikal.
final List<List<double>> _threeSlots = [
  [0.30, 0.193, 0.405, 0.193], // slot foto pertama (atas)
  [0.30, 0.403, 0.405, 0.193], // slot foto kedua (tengah)
  [0.30, 0.613, 0.405, 0.193], // slot foto ketiga (bawah)
];

// Mapping frameId -> daftar slot foto.
// Saat ini semua frame (1-12) memakai layout 3 slot yang sama (_threeSlots).
final Map<int, List<List<double>>> _frameSlots = {
  1: _threeSlots, 2: _threeSlots, 3: _threeSlots,
  4: _threeSlots, 5: _threeSlots, 6: _threeSlots,
  7: _threeSlots, 8: _threeSlots, 9: _threeSlots,
  10: _threeSlots, 11: _threeSlots, 12: _threeSlots,
};

/// Halaman detail satu strip foto dari galeri.
/// Menampilkan preview strip full-screen (dengan frame), dan menyediakan
/// aksi: simpan ke galeri device, bagikan (share), ganti frame, dan hapus.
class GalleryDetailScreen extends StatefulWidget {
  final PhotoSessionModel session;
  const GalleryDetailScreen({super.key, required this.session});

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  // Controller untuk menangkap (screenshot) tampilan strip foto
  // menjadi gambar, dipakai untuk fitur simpan & bagikan.
  final ScreenshotController _screenshotController = ScreenshotController();

  // Flag loading terpisah untuk aksi simpan dan bagikan,
  // supaya tombol yang sedang diproses saja yang menampilkan spinner.
  bool _isSaving = false;
  bool _isSharing = false;

  // Salinan lokal dari session yang bisa berubah (mis. setelah ganti frame),
  // sedangkan widget.session tetap merupakan data awal yang di-passing.
  late PhotoSessionModel _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  // Membuka halaman pemilihan frame, lalu jika user memilih frame baru
  // yang berbeda dari frame saat ini, update sesi via API dan refresh data lokal.
  void _changeFrame() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => FramePickerScreen(
          title: 'Ganti Frame',
          selectedFrameId: _session.frameId,
        ),
      ),
    );
    if (result != null && result != _session.frameId) {
      try {
        await SessionService.update(_session.id, frameId: result);
        // Ambil ulang data sesi terbaru dari backend agar state konsisten.
        final updated = await SessionService.getOne(_session.id);
        setState(() => _session = updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Frame berhasil diganti!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
            ),
          );
        }
      } on ApiException catch (e) {
        // Gagal update frame -> tampilkan pesan error dari API
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
            ),
          );
        }
      }
    }
  }

  // Dialog konfirmasi sebelum menghapus strip. Mengembalikan true jika
  // user menekan "Hapus", false jika "Batal" atau dialog ditutup begitu saja.
  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Strip?'),
        content: Text('Apakah Anda yakin ingin menghapus\n"${_session.title}"?'),
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
    return confirmed ?? false;
  }

  // Hapus sesi foto ini setelah dikonfirmasi, lalu tutup halaman detail
  // dan kembali ke halaman sebelumnya (galeri).
  Future<void> _deleteSession() async {
    final confirmed = await _confirmDelete();
    if (!confirmed) return;
    try {
      await SessionService.remove(_session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Strip berhasil dihapus dari galeri'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
        // Kembali ke layar sebelumnya (galeri) setelah berhasil dihapus.
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
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
  }

  // Menangkap tampilan strip foto sebagai gambar (screenshot), lalu
  // menyimpannya ke galeri foto perangkat (via package `gal`) dan
  // mencatatnya ke riwayat lokal (Hive) supaya muncul di halaman History.
  Future<void> _savePhotoStrip() async {
    if (_isSaving) return; // Cegah proses ganda jika tombol ditekan berkali-kali
    setState(() => _isSaving = true);
    try {
      // Ambil screenshot widget strip dengan resolusi tinggi (pixelRatio 3x)
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Gagal menangkap gambar');

      // Simpan hasil capture ke file sementara terlebih dahulu,
      // karena Gal.putImage & Share membutuhkan path file, bukan bytes langsung.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);

      // Simpan file ke galeri foto bawaan perangkat (Photos/Gallery app)
      await Gal.putImage(tempFile.path);

      // Catat juga ke riwayat lokal (Hive) agar muncul di daftar History.
      // Kegagalan di sini tidak boleh menggagalkan keseluruhan proses simpan,
      // karena gambar sudah berhasil tersimpan ke galeri device.
      try {
        final history = HistoryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: tempFile.path,
          title: '${_session.title} #${DateTime.now().millisecond}',
          createdAt: DateTime.now().toIso8601String(),
          note: 'From My Gallery',
        );
        await HiveService.addHistory(history);
      } catch (e) {
        debugPrint('Gagal simpan ke Hive history: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Strip berhasil disimpan ke galeri!'),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      // Menangkap semua jenis error (capture gagal, tulis file gagal,
      // permission ditolak, dll) dan menampilkannya ke user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Menangkap tampilan strip foto sebagai gambar, lalu membuka
  // share sheet bawaan OS (via package `share_plus`) untuk dibagikan
  // ke aplikasi lain (WhatsApp, Instagram, dll).
  Future<void> _sharePhotoStrip() async {
    if (_isSharing) return; // Cegah proses ganda
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Gagal menangkap gambar');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gallery_strip_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);
      // Buka dialog share OS dengan file gambar + caption default.
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Lihat photostrip buatanku! 📸 #BloomBooth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // Membangun satu foto dalam strip untuk tampilan detail,
  // termasuk penerapan filter warna (color matrix) jika ada.
  Widget _buildDetailPhotoWithEffects(int index, PhotoModel photo) {
    Widget photoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        '${AppConstants.storageUrl}${photo.imagePath}',
        fit: BoxFit.cover,
        // Fallback jika gambar gagal dimuat dari server.
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.secondary.withOpacity(0.15),
          child: const Icon(Icons.broken_image, color: AppColors.secondary),
        ),
      ),
    );

    // Apply color filter if filterName is available
    final filterName = photo.filterName ?? 'Normal';
    if (filterName != 'Normal' && filterMatrices.containsKey(filterName)) {
      photoWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(filterMatrices[filterName]!),
        child: photoWidget,
      );
    }

    return ClipRect(child: photoWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Default ke frame 9 jika sesi tidak punya frameId,
    // dan fallback ke slot frame 9 jika frameId tidak dikenal di _frameSlots.
    final frameId = _session.frameId ?? 9;
    final slots = _frameSlots[frameId] ?? _frameSlots[9]!;
    final photos = _session.photos;
    // Batasi jumlah foto yang dirender sesuai jumlah slot yang tersedia.
    final photoCount = min(photos.length, slots.length);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_session.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          // Tombol hapus di AppBar
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Strip',
            onPressed: _deleteSession,
          ),
        ],
      ),
      body: Column(
        children: [
          // Area preview utama: strip foto + frame, dibungkus Screenshot
          // widget supaya bisa di-capture untuk fitur simpan/bagikan.
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Screenshot(
                  controller: _screenshotController,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Ukuran container dipakai mengonversi koordinat slot
                        // (0.0-1.0) menjadi posisi piksel absolut.
                        final containerWidth = constraints.maxWidth;
                        final containerHeight = constraints.maxHeight;
                        return Stack(
                          children: [
                            // Render tiap foto sesuai posisi slot masing-masing
                            ...List.generate(photoCount, (index) {
                              final slot = slots[index];
                              final photo = photos[index];
                              return Positioned(
                                left: slot[0] * containerWidth,
                                top: slot[1] * containerHeight,
                                width: slot[2] * containerWidth,
                                height: slot[3] * containerHeight,
                              child: _buildDetailPhotoWithEffects(index, photo),
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
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Panel tombol aksi di bagian bawah: Simpan, Bagikan, Ganti Frame
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Simpan',
                        color: AppColors.primary,
                        isLoading: _isSaving,
                        onTap: _savePhotoStrip,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Bagikan',
                        color: AppColors.secondary,
                        isLoading: _isSharing,
                        onTap: _sharePhotoStrip,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.style_outlined,
                  label: 'Ganti Frame',
                  color: Colors.black87,
                  isFullWidth: true,
                  onTap: _changeFrame,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol aksi reusable (icon + label) dengan dukungan state loading
/// (menampilkan spinner menggantikan icon) dan opsi full-width.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;
  final bool isLoading;

  const _ActionButton({
    required this.icon, required this.label, required this.color, required this.onTap,
    this.isFullWidth = false, this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        // Nonaktifkan tombol selama proses loading, supaya tidak ditekan berkali-kali.
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }
}

/// A simple full-screen frame picker for gallery detail.
/// Menampilkan grid pilihan frame yang tersedia; user tap salah satu
/// untuk memilih, lalu konfirmasi dengan FAB checkmark yang muncul
/// setelah ada frame terpilih. Hasil pilihan dikembalikan lewat Navigator.pop.
class FramePickerScreen extends StatefulWidget {
  final String title;
  final int? selectedFrameId;
  const FramePickerScreen({super.key, this.title = 'Pilih Frame', this.selectedFrameId});

  @override
  State<FramePickerScreen> createState() => _FramePickerScreenState();
}

class _FramePickerScreenState extends State<FramePickerScreen> {
  List<FrameModel> _frames = [];
  bool _isLoading = true;
  // Id frame yang sedang dipilih user; diinisialisasi dengan frame yang
  // sudah aktif sebelumnya (jika ada) supaya terlihat ter-highlight.
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedFrameId;
    _loadFrames();
  }

  // Mengambil daftar frame yang tersedia dari backend.
  Future<void> _loadFrames() async {
    setState(() => _isLoading = true);
    try {
      final data = await FrameService.getAll();
      if (mounted) setState(() => _frames = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat frame: $e'),
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const LoadingView()
          : _frames.isEmpty
              ? const EmptyView(message: 'Tidak ada frame tersedia', icon: Icons.style)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: _frames.length,
                  itemBuilder: (ctx, i) {
                    final frame = _frames[i];
                    final id = frame.id;
                    return GestureDetector(
                      // Tap kartu frame untuk memilihnya (belum langsung konfirmasi).
                      onTap: () => setState(() => _selectedId = id),
                      child: Container(
                        decoration: BoxDecoration(
                          // Border biru + lebih tebal untuk frame yang sedang dipilih.
                          border: Border.all(
                            color: _selectedId == id ? Colors.blue : Colors.grey,
                            width: _selectedId == id ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/frames/$id.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.secondary.withOpacity(0.15),
                                    child: const Icon(Icons.broken_image, color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                            // Label nama frame di bawah thumbnail
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              color: Colors.black54,
                              width: double.infinity,
                              child: Text(
                                frame.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      // FAB konfirmasi hanya muncul jika sudah ada frame yang dipilih.
      // Menekan FAB akan mengembalikan id frame terpilih ke layar pemanggil.
      floatingActionButton: _selectedId == null
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pop(context, _selectedId),
              child: const Icon(Icons.check),
            ),
    );
  }
}