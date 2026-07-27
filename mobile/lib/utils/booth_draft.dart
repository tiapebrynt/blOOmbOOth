import 'dart:io';

/// Menyimpan state sementara selama alur:
/// Live Camera -> Frame Selection -> Filter Library -> Vibe Lighting
/// -> Beauty Enhancement -> Final Preview (baru di-submit ke backend).
class BoothDraft {
  
  List<File> capturedPhotos = [];
  String layoutType;
  int? frameId;
  String? frameName;
  int? colorFilterId;
  String? colorFilterName;
  int? vibeFilterId;
  String? vibeFilterName;
  double vibeIntensity;
  double beautySmooth;
  double beautyBrighten;

  // Field untuk LiveCamera studio (global default)
  String selectedEffect = 'Normal';
  String selectedFilter = 'Normal';
  String selectedVibe = 'Normal';
  Map<String, List<double>> filterMatrices = {};

  // Per-slot settings — index sesuai urutan capturedPhotos
  List<String> slotFilters = [];
  List<String> slotEffects = [];
  List<String> slotVibes = [];

  BoothDraft({this.layoutType = '4-cut'})
      : vibeIntensity = 0.5,
        beautySmooth = 0.3,
        beautyBrighten = 0.3;

  int get requiredShotCount {
    switch (layoutType) {
      case '2-cut':
        return 2;
      case '6-cut':
        return 6;
      default:
        return 4;
    }
  }
}
