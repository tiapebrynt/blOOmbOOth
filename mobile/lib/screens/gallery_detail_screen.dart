import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../models/photo_session_model.dart';
import '../models/history_model.dart';
import '../models/frame_model.dart';
import '../services/session_service.dart';
import '../services/frame_service.dart';
import '../services/api_client.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/state_views.dart';

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

class GalleryDetailScreen extends StatefulWidget {
  final PhotoSessionModel session;
  const GalleryDetailScreen({super.key, required this.session});

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;
  bool _isSharing = false;

  late PhotoSessionModel _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

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
        final updated = await SessionService.getOne(_session.id);
        setState(() => _session = updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Frame berhasil diganti!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }

  Future<void> _savePhotoStrip() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Gagal menangkap gambar');

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);
      await Gal.putImage(tempFile.path);

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sharePhotoStrip() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Gagal menangkap gambar');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gallery_strip_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Lihat photostrip buatanku! 📸 #BloomBooth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameId = _session.frameId ?? 9;
    final slots = _frameSlots[frameId] ?? _frameSlots[9]!;
    final photos = _session.photos;
    final photoCount = min(photos.length, slots.length);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_session.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Ganti Frame',
            onPressed: _changeFrame,
          ),
        ],
      ),
      body: Column(
        children: [
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
                                      child: const Icon(Icons.broken_image, color: AppColors.secondary),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
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
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedFrameId;
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    setState(() => _isLoading = true);
    try {
      final data = await FrameService.getAll();
      if (mounted) setState(() => _frames = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat frame: $e')),
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
                      onTap: () => setState(() => _selectedId = id),
                      child: Container(
                        decoration: BoxDecoration(
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
      floatingActionButton: _selectedId == null
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pop(context, _selectedId),
              child: const Icon(Icons.check),
            ),
    );
  }
}

