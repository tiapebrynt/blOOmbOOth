import 'package:flutter/material.dart';
import '../models/photo_session_model.dart';
import '../services/session_service.dart';
import '../services/api_client.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';

/// Halaman detail sederhana untuk satu strip foto (identik secara data
/// dengan GalleryDetailScreen, tapi tanpa preview frame/screenshot).
/// Menampilkan judul, info singkat (frame/jumlah foto/dekorasi), grid foto,
/// serta aksi: rename judul, toggle favorit, dan hapus strip.
class StripDetailScreen extends StatefulWidget {
  final int sessionId;
  const StripDetailScreen({super.key, required this.sessionId});

  @override
  State<StripDetailScreen> createState() => _StripDetailScreenState();
}

class _StripDetailScreenState extends State<StripDetailScreen> {
  // Future yang menampung data detail sesi foto, diambil berdasarkan sessionId.
  late Future<PhotoSessionModel> _future;

  @override
  void initState() {
    super.initState();
    _future = SessionService.getOne(widget.sessionId);
  }

  // Memuat ulang data sesi (dipanggil setelah rename, toggle favorit, atau retry).
  Future<void> _refresh() async {
    setState(() => _future = SessionService.getOne(widget.sessionId));
  }

  // Membalik status favorit sesi (favorit -> tidak, atau sebaliknya) via API,
  // lalu refresh data agar UI menampilkan status terbaru.
  Future<void> _toggleFavorite(PhotoSessionModel session) async {
    try {
      await SessionService.update(session.id, isFavorite: !session.isFavorite);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
        ),
      );
    }
  }

  // Menampilkan dialog input teks untuk mengubah judul strip.
  // Jika judul baru tidak kosong, kirim update ke API dan refresh data.
  Future<void> _renameStrip(PhotoSessionModel session) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Judul Strip'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    // Hanya proses jika user menekan "Simpan" (bukan batal/tutup dialog)
    // dan judul barunya tidak kosong.
    if (newTitle != null && newTitle.isNotEmpty) {
      try {
        await SessionService.update(session.id, title: newTitle);
        _refresh();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    }
  }

  // Menampilkan dialog konfirmasi, lalu jika dikonfirmasi, hapus strip
  // via API dan tutup halaman detail ini (kembali ke layar sebelumnya).
  Future<void> _deleteStrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Strip?'),
        content: const Text('Strip ini akan dihapus permanen dari My Gallery.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SessionService.remove(widget.sessionId);
        if (mounted) Navigator.of(context).pop();
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strip Detail'),
        actions: [
          // Tombol hapus di AppBar
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteStrip),
        ],
      ),
      body: FutureBuilder<PhotoSessionModel>(
        future: _future,
        builder: (context, snapshot) {
          // Selama data belum selesai dimuat, tampilkan loading state
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          // Jika gagal fetch, tampilkan pesan error + tombol retry
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Gagal memuat detail strip.',
              onRetry: _refresh,
            );
          }
          final session = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Baris judul + tombol edit + tombol favorit
                Row(
                  children: [
                    Expanded(
                      child: Text(session.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _renameStrip(session),
                    ),
                    IconButton(
                      // Icon hati berubah bentuk (solid/outline) sesuai status favorit
                      icon: Icon(
                        session.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _toggleFavorite(session),
                    ),
                  ],
                ),
                // Info ringkas: nama frame, jumlah foto, jumlah dekorasi
                Text(
                  'Frame: ${session.frameName ?? "-"}  •  ${session.photos.length} foto  •  ${session.decorations.length} dekorasi',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                // Grid foto-foto dalam strip; jika kosong, tampilkan empty state
                Expanded(
                  child: session.photos.isEmpty
                      ? const EmptyView(message: 'Strip ini belum memiliki foto')
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: session.photos.length,
                          itemBuilder: (context, i) {
                            final photo = session.photos[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                '${AppConstants.storageUrl}${photo.imagePath}',
                                fit: BoxFit.cover,
                                // Fallback ikon jika gambar gagal dimuat dari server
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  child: const Icon(Icons.broken_image, color: AppColors.secondary),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}