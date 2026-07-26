import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'dart:typed_data';
import '../utils/booth_draft.dart';
import '../utils/theme.dart';
import '../utils/filter_data.dart';
import '../models/history_model.dart';
import '../models/photo_model.dart';
import '../services/hive_service.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import 'home_shell.dart';
//ahnafm
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

class ResultScreen extends StatefulWidget {
  final BoothDraft draft;
  const ResultScreen({super.key, required this.draft});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final frameId = draft.frameId ?? 9;
    final slots = _frameSlots[frameId] ?? _frameSlots[9]!;
    final photoCount = min(draft.capturedPhotos.length, slots.length);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hasil Photostrip"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
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
                              return Positioned(
                                left: slot[0] * containerWidth,
                                top: slot[1] * containerHeight,
                                width: slot[2] * containerWidth,
                                height: slot[3] * containerHeight,
                                child: _buildPhotoWithEffects(index, draft),
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
                  icon: Icons.camera_alt_rounded,
                  label: 'Kembali ke Home',
                  color: Colors.black87,
                  isFullWidth: true,
                  onTap: () => _goToHome(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhotoStrip() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Gagal menangkap gambar');

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/photobooth_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);
      await Gal.putImage(tempFile.path);

      try {
        final history = HistoryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: tempFile.path,
          title: 'Photostrip #${DateTime.now().millisecond}',
          createdAt: DateTime.now().toIso8601String(),
          note: 'Frame ${widget.draft.frameId ?? 9}',
        );
        await HiveService.addHistory(history);
      } catch (e) {
        debugPrint('Gagal simpan ke Hive history: $e');
      }

      try {
        final draft = widget.draft;
        final photos = <PhotoModel>[];
        for (var i = 0; i < draft.capturedPhotos.length; i++) {
          final file = draft.capturedPhotos[i];
          final uploadRes = await ApiClient.uploadImage('/uploads', file.path);
          photos.add(PhotoModel(
            id: 0, sessionId: 0,
            imagePath: uploadRes['data']['path'],
            orderIndex: i,
            filterId: draft.colorFilterId ?? draft.vibeFilterId,
            beautySmooth: 0.3, beautyBrighten: 0.3,
          ));
        }
        await SessionService.create(
          frameId: draft.frameId,
          title: 'Photostrip #${DateTime.now().millisecond}',
          layoutType: draft.layoutType,
          photos: photos,
        );
      } catch (e) {
        debugPrint('Gagal simpan ke My Gallery backend: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Foto strip berhasil disimpan ke galeri & My Gallery!'),
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
      final tempFile = File('${tempDir.path}/photobooth_strip_${DateTime.now().millisecondsSinceEpoch}.png');
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

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()), (route) => false,
    );
  }

  Widget _buildPhotoWithEffects(int index, BoothDraft draft) {
    final file = draft.capturedPhotos[index];
    Widget photo = AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: kIsWeb ? Image.network(file.path, fit: BoxFit.cover) : Image.file(file, fit: BoxFit.cover),
      ),
    );
    final filter = index < draft.slotFilters.length ? draft.slotFilters[index] : draft.selectedFilter;
    final effect = index < draft.slotEffects.length ? draft.slotEffects[index] : draft.selectedEffect;
    final vibe = index < draft.slotVibes.length ? draft.slotVibes[index] : draft.selectedVibe;

    if (filter != 'Normal' && filterMatrices.containsKey(filter)) {
      photo = ColorFiltered(colorFilter: ColorFilter.matrix(filterMatrices[filter]!), child: photo);
    }
    photo = _applyEffectToPhoto(photo, effect);
    photo = _applyVibeToPhoto(photo, vibe);
    return photo;
  }

  Widget _applyEffectToPhoto(Widget child, String effect) {
    switch (effect) {
      case 'Dreamy Blur':
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), child: child),
        );
      case 'Retro Grain':
        return Stack(children: [child, Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GrainPainter())))]);
      case 'Sparkle':
        return Stack(children: [child, Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _SparklePainter())))]);
      case 'Neon Glow':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
        );
      case 'Vignette':
        return Stack(children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    stops: const [0.5, 1.0], radius: 0.9,
                  ),
                ),
              ),
            ),
          ),
        ]);
      case 'Soft Glow':
        return Stack(children: [
          child,
          Opacity(
            opacity: 0.15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0), child: child),
            ),
          ),
        ]);
      case 'Glitch':
        return Stack(children: [child, Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GlitchPainter())))]);
      case 'Chromatic':
        return Stack(children: [
          Transform.translate(
            offset: const Offset(2, 0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0.5,0]),
              child: child,
            ),
          ),
          Transform.translate(
            offset: const Offset(-2, 0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([0,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,0.5,0]),
              child: child,
            ),
          ),
          child,
        ]);
      case 'Film Dust':
        return Stack(children: [child, Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FilmDustPainter())))]);
      case 'Light Leak':
        return Stack(children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight, end: Alignment.bottomLeft,
                    colors: [Colors.orange.withValues(alpha: 0.2), Colors.yellow.withValues(alpha: 0.1), Colors.transparent, Colors.transparent],
                    stops: const [0.0, 0.2, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ]);
      case 'Bokeh':
        return Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0), child: child),
          ),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BokehPainter()))),
        ]);
      default:
        return child;
    }
  }

  Widget _applyVibeToPhoto(Widget child, String vibe) {
    if (vibe == 'Normal') return child;
    Color? vibeColor;
    for (final v in vibesList) {
      if (v.name == vibe) { vibeColor = v.color; break; }
    }
    if (vibeColor == null || vibeColor == Colors.transparent) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Stack(children: [
        child,
        Positioned.fill(child: IgnorePointer(child: Container(color: vibeColor))),
      ]),
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

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final paint = Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.5 + 0.3);
      canvas.drawCircle(Offset(x, y), radius, paint);
      final crossPaint = Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 0.5;
      canvas.drawLine(Offset(x - radius * 2, y), Offset(x + radius * 2, y), crossPaint);
      canvas.drawLine(Offset(x, y - radius * 2), Offset(x, y + radius * 2), crossPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrainPainter extends CustomPainter {
  final List<Color> _grainColors = [
    Colors.black12, Colors.black26, Colors.black12, Colors.transparent,
    Colors.black38, Colors.transparent, Colors.black12, Colors.black26,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final color = _grainColors[random.nextInt(_grainColors.length)];
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5 + 0.5, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final y = random.nextDouble() * size.height;
      final h = random.nextDouble() * 4 + 2;
      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.15);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
      paint.color = Colors.cyanAccent.withValues(alpha: 0.05);
      canvas.drawRect(Rect.fromLTWH(random.nextDouble() * size.width * 0.5, y, size.width * 0.4, h), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilmDustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final paint = Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.08)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.0 + 0.3, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BokehPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 15 + 5;
      final paint = Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.06)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
