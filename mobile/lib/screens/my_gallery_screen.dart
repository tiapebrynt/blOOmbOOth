import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/photo_session_model.dart';
import '../services/session_service.dart';
import '../services/api_client.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';
import 'gallery_detail_screen.dart';

final List<List<double>> _threeSlots = [
  [0.30, 0.193, 0.405, 0.193],
  [0.30, 0.403, 0.405, 0.193],
  [0.30, 0.613, 0.405, 0.193],
];

final Map<int, List<List<double>>> _frameSlots = {
  1: _threeSlots, 2: _threeSlots, 3: _threeSlots,
  4: _threeSlots, 5: _threeSlots, 6: _threeSlots,
  7: _threeSlots, 8: _threeSlots, 9: _threeSlots,
  10: _threeSlots, 11: _threeSlots, 12: _threeSlots,
};

class MyGalleryScreen extends StatefulWidget {
  const MyGalleryScreen({super.key});

  @override
  State<MyGalleryScreen> createState() => _MyGalleryScreenState();
}

class _MyGalleryScreenState extends State<MyGalleryScreen> {
  late Future<List<PhotoSessionModel>> _future;
  String _query = '';
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _future = SessionService.getAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = SessionService.getAll());
  }

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
    return confirmed ?? false;
  }

  Future<void> _deleteSession(PhotoSessionModel session) async {
    final confirmed = await _confirmDelete(session);
    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await SessionService.remove(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Strip berhasil dihapus dari galeri'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
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
            const Text('My Gallery',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari strip...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<PhotoSessionModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingView();
                    }
                    if (snapshot.hasError) {
                      return ErrorView(
                        message: snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : 'Gagal memuat galeri. Periksa koneksi ke backend.',
                        onRetry: _refresh,
                      );
                    }
                    var sessions = snapshot.data ?? [];
                    if (_query.isNotEmpty) {
                      sessions = sessions
                          .where((s) => s.title.toLowerCase().contains(_query))
                          .toList();
                    }
                    if (sessions.isEmpty) {
                      return const EmptyView(message: 'Belum ada strip tersimpan.\nYuk mulai photobooth!');
                    }
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
                              final fullSession = await SessionService.getOne(session.id);
                              if (!mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GalleryDetailScreen(session: fullSession),
                                ),
                              );
                            } on ApiException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                                );
                              }
                            }
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
    final frameId = session.frameId ?? 9;
    final slots = _frameSlots[frameId] ?? _frameSlots[9]!;
    final photos = session.photos;
    final photoCount = min(photos.length, slots.length);

    return GestureDetector(
      onTap: isDeleting ? null : onTap,
      child: Dismissible(
        key: Key('gallery_${session.id}'),
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
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Mini photostrip preview with frame overlay
                      if (photoCount > 0)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final containerWidth = constraints.maxWidth;
                            final containerHeight = constraints.maxHeight;
                            return Stack(
                              children: [
                                ...List.generate(photoCount, (index) {
                                  final slot = slots[index];
                                  final photo = photos[index];
                                  return Positioned(
                                    left: slot[0] * containerWidth,
                                    top: slot[1] * containerHeight,
                                    width: slot[2] * containerWidth,
                                    height: slot[3] * containerHeight,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Image.network(
                                        '${AppConstants.storageUrl}${photo.imagePath}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.secondary.withOpacity(0.15),
                                          child: const Icon(Icons.broken_image, color: AppColors.secondary, size: 18),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
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
                        _placeholder(),
                      // Delete button overlay on top right
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

  Widget _placeholder() => Container(
        color: AppColors.secondary.withOpacity(0.15),
        child: const Center(child: Icon(Icons.photo, color: AppColors.secondary, size: 40)),
      );
}

String _formatDate(String raw) {
  try {
    final date = DateTime.parse(raw);
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  } catch (_) {
    return raw.split(' ').first;
  }
}

