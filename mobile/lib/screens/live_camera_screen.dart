import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import '../utils/booth_draft.dart';
import '../utils/filter_data.dart';
import '../widgets/countdown_overlay.dart';
import 'result_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
//ahnafm
class LiveCameraScreen extends StatefulWidget {
  final bool embedded;
  final int shotCount;
  final String frameId;

  const LiveCameraScreen({
    super.key,
    this.embedded = false,
    required this.shotCount,
    required this.frameId,
  });

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initFuture;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _showCountdown = false;
  int _selectedCountdown = 3;
  late BoothDraft _draft;

  bool _isReviewingAll = false;
  bool _showStudioPanel = false;
  int? _retakeIndex;

  String _selectedFilter = 'Normal';
  String _selectedEffect = 'Normal';
  String _selectedVibe = 'Normal';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _draft = BoothDraft();
    _draft.frameId = int.tryParse(widget.frameId);
    _initCamera();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureWithCountdown() async {
    setState(() => _showCountdown = true);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Kamera tidak tersedia: $e');
    }
  }

  Future<void> _reinitCamera(int index) async {
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _reinitCamera(_cameraIndex);
    // Re-apply flash mode after switching camera
    await _applyFlashMode();
  }

  void _toggleFlash() {
    final modes = FlashMode.values;
    final currentIndex = modes.indexOf(_flashMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    setState(() {
      _flashMode = modes[nextIndex];
    });
    _applyFlashMode();
  }

  Future<void> _applyFlashMode() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFlashMode(_flashMode);
      }
    } catch (e) {
      debugPrint('Gagal mengatur flash mode: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flashlight_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  String _getFlashLabel() {
    switch (_flashMode) {
      case FlashMode.always:
        return 'Nyala';
      case FlashMode.auto:
        return 'Auto';
      case FlashMode.torch:
        return 'Torch';
      case FlashMode.off:
      default:
        return 'Mati';
    }
  }

  Future<void> _onCountdownFinished() async {
    setState(() => _showCountdown = false);
    try {
      File? capturedFile;
      if (_controller != null && _controller!.value.isInitialized) {
        final file = await _controller!.takePicture();
        capturedFile = File(file.path);
      } else {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) capturedFile = File(picked.path);
      }

      if (capturedFile != null) {
        setState(() {
          if (_retakeIndex != null) {
            // Retake: ganti foto dan langsung balik ke review
            _draft.capturedPhotos[_retakeIndex!] = capturedFile!;
            _draft.slotFilters[_retakeIndex!] = _selectedFilter;
            _draft.slotEffects[_retakeIndex!] = _selectedEffect;
            _draft.slotVibes[_retakeIndex!] = _selectedVibe;
            _retakeIndex = null;
            _isReviewingAll = true;
          } else {
            _draft.capturedPhotos.add(capturedFile!);
            _draft.slotFilters.add(_selectedFilter);
            _draft.slotEffects.add(_selectedEffect);
            _draft.slotVibes.add(_selectedVibe);
            if (_draft.capturedPhotos.length >= widget.shotCount) {
              _isReviewingAll = true;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _goToNextStep() {
    // Simpan semua pengaturan
    _draft.selectedFilter = _selectedFilter;
    _draft.selectedEffect = _selectedEffect;
    _draft.selectedVibe = _selectedVibe;
    _draft.filterMatrices = Map<String, List<double>>.from(filterMatrices);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(draft: _draft),
      ),
    );
  }

  void _openStudioMenu() {
    setState(() => _showStudioPanel = true);
  }

  void _closeStudioPanel() {
    setState(() => _showStudioPanel = false);
  }

/// Inline studio panel — langsung di Stack tanpa freeze kamera
  Widget _buildStudioPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar + close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeStudioPanel,
                    child: const Icon(Icons.close, color: Colors.white70, size: 24),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 14),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: "Filter"),
                Tab(text: "Effect"),
                Tab(text: "Vibe"),
              ],
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterTab(),
                  _buildEffectTab(),
                  _buildVibeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      children: filterMatrices.keys.map((name) {
        final isSelected = _selectedFilter == name;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = name),
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white10,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEffectTab() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: effectsList.length,
      itemBuilder: (context, i) {
        final effect = effectsList[i];
        final isSelected = _selectedEffect == effect['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedEffect = effect['name'] as String),
          child: Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white10,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  effect['icon'] as IconData,
                  color: isSelected ? AppColors.primary : Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  effect['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVibeTab() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: vibesList.length,
      itemBuilder: (context, i) {
        final vibe = vibesList[i];
        final isSelected = _selectedVibe == vibe.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedVibe = vibe.name),
          child: Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white10,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: vibe.color == Colors.transparent
                        ? Colors.white24
                        : vibe.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: vibe.color == Colors.transparent
                          ? Colors.white38
                          : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vibe.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Camera preview (sembunyikan saat review)
            Offstage(
              offstage: _isReviewingAll,
              child: Positioned.fill(child: _buildPreview()),
            ),
            // Review grid overlay
            if (_isReviewingAll)
              Positioned.fill(child: _buildReviewGridOverlay()),
            // Camera controls (sembunyikan saat review)
            if (!_isReviewingAll)
              Positioned.fill(child: _buildCameraControls()),
            // Countdown overlay
            if (_showCountdown)
              Positioned.fill(
                child: CountdownOverlay(
                  seconds: _selectedCountdown,
                  onFinished: _onCountdownFinished,
                ),
              ),
            // Background dimmer untuk studio panel (hindari interaksi kamera)
            if (_showStudioPanel && !_isReviewingAll)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeStudioPanel,
                  child: Container(color: Colors.black45),
                ),
              ),
            // Studio panel overlay (inline — tidak freeze kamera)
            if (_showStudioPanel && !_isReviewingAll)
              _buildStudioPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Stack(
      children: [
        // Tombol SWITCH CAMERA + FLASH (atas kiri, berjejer vertikal)
        Positioned(
          top: 48,
          left: 16,
          child: SafeArea(
            child: Column(
              children: [
                // Tombol Switch Kamera
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _cameras.length > 1 ? _switchCamera : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol Flash
                CircleAvatar(
                  backgroundColor: _flashMode != FlashMode.off
                      ? AppColors.primary
                      : Colors.black54,
                  child: IconButton(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 22),
                    onPressed: _toggleFlash,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tombol STUDIO MENU (atas kanan)
        Positioned(
          top: 48,
          right: 16,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                onPressed: _openStudioMenu,
              ),
            ),
          ),
        ),
        // Info studio aktif (sembunyikan saat countdown)
        // Info studio aktif (tarik sedikit ke atas agar tidak menabrak pilihan detik)
        if (!_showCountdown)
          Positioned(
            bottom: 150, // Naikkan posisinya dari 110 ke 150
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Filter: $_selectedFilter • Effect: $_selectedEffect • Vibe: $_selectedVibe',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        // Tombol CAPTURE (bawah tengah)
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Countdown selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [3, 5, 10].map((sec) {
                  final isSelected = _selectedCountdown == sec;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCountdown = sec),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${sec}s',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showCountdown ? null : _captureWithCountdown,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _retakePhoto(int index) {
    setState(() {
      _retakeIndex = index;
      _isReviewingAll = false;
    });
    // Kembali ke kamera — user harus klik capture manual (countdown dulu, baru capture)
  }

  /// Review screen — menampilkan foto dengan filter/effect/vibe per-slot
  Widget _buildReviewGridOverlay() {
    return Container(
      color: Colors.grey.shade900,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Review Foto",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: _draft.capturedPhotos.length,
                  itemBuilder: (context, index) {
                    // Ambil per-slot settings
                    final slotFilter = index < _draft.slotFilters.length
                        ? _draft.slotFilters[index]
                        : _selectedFilter;
                    final slotEffect = index < _draft.slotEffects.length
                        ? _draft.slotEffects[index]
                        : _selectedEffect;
                    final slotVibe = index < _draft.slotVibes.length
                        ? _draft.slotVibes[index]
                        : _selectedVibe;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          // Photo preview with filter/effect/vibe applied
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 3 / 2,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Base photo with effects applied
                                  _buildReviewPhotoWithEffects(
                                    _draft.capturedPhotos[index],
                                    slotFilter,
                                    slotEffect,
                                    slotVibe,
                                  ),
                                  // Tombol Retake
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _retakePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.replay,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Retake',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Label foto ke-
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Foto ${index + 1} dari ${widget.shotCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text(
                  "Lanjut ke Frame",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build photo review with per-slot filter/effect/vibe applied
  /// Order: Filter (matrix) → Effects → Vibe (color overlay on image only)
  Widget _buildReviewPhotoWithEffects(File file, String filter, String effect, String vibe) {
    Widget photo = kIsWeb
        ? Image.network(file.path, fit: BoxFit.cover)
        : Image.file(file, fit: BoxFit.cover);

    // 1. COLOR FILTER (matrix)
    if (filter != 'Normal' && filterMatrices.containsKey(filter)) {
      photo = ColorFiltered(
        colorFilter: ColorFilter.matrix(filterMatrices[filter]!),
        child: photo,
      );
    }

    // 2. EFFECTS
    photo = _applyEffectToReviewPhoto(photo, effect);

    // 3. VIBE COLOR — applied as ColorFilter on image only (not full container),
    //    preventing color spill on the sides
    if (vibe != 'Normal') {
      Color? vibeColor;
      for (final v in vibesList) {
        if (v.name == vibe) {
          vibeColor = v.color;
          break;
        }
      }
      if (vibeColor != null && vibeColor != Colors.transparent) {
        photo = ColorFiltered(
          colorFilter: ColorFilter.mode(vibeColor, BlendMode.srcOver),
          child: photo,
        );
      }
    }

    return photo;
  }

  Widget _applyEffectToReviewPhoto(Widget child, String effect) {
    switch (effect) {
      case 'Dreamy Blur':
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: child,
          ),
        );
      case 'Retro Grain':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _LiveGrainPainter()),
              ),
            ),
          ],
        );
      case 'Sparkle':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _LiveSparklePainter()),
              ),
            ),
          ],
        );
      case 'Neon Glow':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
            ],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
        );
      case 'Vignette':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                      stops: const [0.5, 1.0],
                      radius: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Soft Glow':
        return Stack(
          children: [
            child,
            Opacity(
              opacity: 0.15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: child,
                ),
              ),
            ),
          ],
        );
      case 'Glitch':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GlitchPainter()),
              ),
            ),
          ],
        );
      case 'Chromatic':
        return Stack(
          children: [
            Transform.translate(
              offset: const Offset(2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0]),
                child: child,
              ),
            ),
            Transform.translate(
              offset: const Offset(-2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0.5, 0]),
                child: child,
              ),
            ),
            child,
          ],
        );
      case 'Film Dust':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FilmDustPainter()),
              ),
            ),
          ],
        );
      case 'Light Leak':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight, end: Alignment.bottomLeft,
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.yellow.withValues(alpha: 0.1),
                        Colors.transparent, Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Bokeh':
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BokehPainter()),
              ),
            ),
          ],
        );
      default:
        return child;
    }
  }

  // ==== PREVIEW KAMERA DENGAN FILTER/EFFECT/VIBE REAL-TIME ====
  // Pakai dedicated widget agar CameraPreview tidak rebuild tiap setState
  Widget _buildPreview() {
    if (_controller == null || _initFuture == null) {
      return const Center(
        child: Text(
          'Kamera tidak terdeteksi.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return _CameraPreviewWidget(
      controller: _controller!,
      initFuture: _initFuture,
      selectedFilter: _selectedFilter,
      selectedEffect: _selectedEffect,
      selectedVibe: _selectedVibe,
    );
  }

  /// Apply selected effect to the preview/widget
  Widget _applyEffect(Widget child) {
    switch (_selectedEffect) {
      case 'Dreamy Blur':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: child,
          ),
        );
      case 'Retro Grain':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LiveGrainPainter(),
                ),
              ),
            ),
          ],
        );
      case 'Sparkle':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LiveSparklePainter(),
                ),
              ),
            ),
          ],
        );
      case 'Neon Glow':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: child,
          ),
        );
      case 'Vignette':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.5, 1.0],
                      radius: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Soft Glow':
        return Stack(
          children: [
            child,
            Opacity(
              opacity: 0.15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: child,
                ),
              ),
            ),
          ],
        );
      case 'Glitch':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GlitchPainter(),
                ),
              ),
            ),
          ],
        );
      case 'Chromatic':
        return Stack(
          children: [
            // Shift red channel
            Transform.translate(
              offset: const Offset(2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0.5, 0,
                ]),
                child: child,
              ),
            ),
            // Shift cyan channel
            Transform.translate(
              offset: const Offset(-2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0, 0, 0, 0, 0,
                  0, 1, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  0, 0, 0, 0.5, 0,
                ]),
                child: child,
              ),
            ),
            // Normal center
            child,
          ],
        );
      case 'Film Dust':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FilmDustPainter(),
                ),
              ),
            ),
          ],
        );
      case 'Light Leak':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.yellow.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Bokeh':
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BokehPainter(),
                ),
              ),
            ),
          ],
        );
      default:
        return child;
    }
  }

  /// Apply vibe color overlay
  Widget _applyVibe(Widget child) {
    if (_selectedVibe == 'Normal') return child;

    Color? vibeColor;
    for (final v in vibesList) {
      if (v.name == _selectedVibe) {
        vibeColor = v.color;
        break;
      }
    }
    if (vibeColor == null || vibeColor == Colors.transparent) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: vibeColor),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOM PAINTERS
// ============================================================

class _LiveSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      paint.color = Colors.white
          .withValues(alpha: random.nextDouble() * 0.5 + 0.3);
      canvas.drawCircle(Offset(x, y), radius, paint);

      final crossPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(x - radius * 2, y),
        Offset(x + radius * 2, y),
        crossPaint,
      );
      canvas.drawLine(
        Offset(x, y - radius * 2),
        Offset(x, y + radius * 2),
        crossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveGrainPainter extends CustomPainter {
  final List<Color> _grainColors = [
    Colors.black12,
    Colors.black26,
    Colors.black12,
    Colors.transparent,
    Colors.black38,
    Colors.transparent,
    Colors.black12,
    Colors.black26,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final color = _grainColors[random.nextInt(_grainColors.length)];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.5 + 0.5,
        paint,
      );
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

      // Baris offset kecil
      paint.color = Colors.cyanAccent.withValues(alpha: 0.05);
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width * 0.5,
          y,
          size.width * 0.4,
          h,
        ),
        paint,
      );
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
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: random.nextDouble() * 0.08,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.0 + 0.3,
        paint,
      );
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
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: random.nextDouble() * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// DEDICATED CAMERA PREVIEW WIDGET — mencegah freeze saat filter diubah
// ============================================================

class _CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;
  final Future<void>? initFuture;
  final String selectedFilter;
  final String selectedEffect;
  final String selectedVibe;

  const _CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.initFuture,
    required this.selectedFilter,
    required this.selectedEffect,
    required this.selectedVibe,
  });

  @override
  State<_CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<_CameraPreviewWidget> {
  // Track apakah ini kamera depan untuk mirror
  bool get _isFrontCamera {
    try {
      final desc = widget.controller.description;
      return desc.lensDirection == CameraLensDirection.front;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initFuture == null) {
      return const Center(
        child: Text(
          'Kamera tidak terdeteksi.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // FutureBuilder hanya untuk initialisasi — setelah done, CameraPreview
    // tidak akan rebuild saat parent setState karena widget ini punya key sendiri
    return FutureBuilder(
      future: widget.initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Widget preview = _buildCameraLayer();

          // 1. COLOR FILTER (matrix filter)
          if (widget.selectedFilter != 'Normal' &&
              filterMatrices.containsKey(widget.selectedFilter)) {
            preview = ColorFiltered(
              colorFilter: ColorFilter.matrix(
                filterMatrices[widget.selectedFilter]!,
              ),
              child: preview,
            );
          }

          // 2. EFFECTS
          preview = _applyEffect(preview);

          // 3. VIBE overlay
          preview = _applyVibe(preview);

          return preview;
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }


  Widget _buildCameraLayer() {
    Widget preview = Center(
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: widget.controller.value.previewSize?.height ?? 100,
              height: widget.controller.value.previewSize?.width ?? 100,
              child: CameraPreview(widget.controller),
            ),
          ),
        ),
      ),
    );

    return preview;
  }

  /// Apply selected effect
  Widget _applyEffect(Widget child) {
    switch (widget.selectedEffect) {
      case 'Dreamy Blur':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: child,
          ),
        );
      case 'Retro Grain':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _LiveGrainPainter()),
              ),
            ),
          ],
        );
      case 'Sparkle':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _LiveSparklePainter()),
              ),
            ),
          ],
        );
      case 'Neon Glow':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: child,
          ),
        );
      case 'Vignette':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.5, 1.0],
                      radius: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Soft Glow':
        return Stack(
          children: [
            child,
            Opacity(
              opacity: 0.15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: child,
                ),
              ),
            ),
          ],
        );
      case 'Glitch':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GlitchPainter()),
              ),
            ),
          ],
        );
      case 'Chromatic':
        return Stack(
          children: [
            Transform.translate(
              offset: const Offset(2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0, 0,
                  0, 0, 0, 0.5, 0,
                ]),
                child: child,
              ),
            ),
            Transform.translate(
              offset: const Offset(-2, 0),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0, 0, 0, 0, 0,
                  0, 1, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  0, 0, 0, 0.5, 0,
                ]),
                child: child,
              ),
            ),
            child,
          ],
        );
      case 'Film Dust':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FilmDustPainter()),
              ),
            ),
          ],
        );
      case 'Light Leak':
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.yellow.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Bokeh':
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                child: child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BokehPainter()),
              ),
            ),
          ],
        );
      default:
        return child;
    }
  }

/// Apply vibe color overlay
  Widget _applyVibe(Widget child) {
    if (widget.selectedVibe == 'Normal') return child;

    Color? vibeColor;
    for (final v in vibesList) {
      if (v.name == widget.selectedVibe) {
        vibeColor = v.color;
        break;
      }
    }
    if (vibeColor == null || vibeColor == Colors.transparent) return child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: vibeColor),
            ),
          ),
        ],
      ),
    );
  }
}

