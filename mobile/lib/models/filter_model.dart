/// Model yang merepresentasikan data Filter.
/// Digunakan untuk menyimpan dan mengelola informasi filter
/// yang diterima dari backend maupun dikirim ke backend.
class FilterModel {

  /// ID unik filter
  final int id;

  /// Nama filter
  final String name;

  /// Jenis filter
  /// Contoh:
  /// - color
  /// - vibe_lighting
  /// - beauty
  final String type;

  /// Lokasi atau path thumbnail filter (opsional)
  final String? thumbnailPath;

  /// Nilai intensitas default filter
  /// Nilai bawaan = 0.5
  final double intensityDefault;

  /// Constructor untuk membuat objek FilterModel
  FilterModel({
    required this.id,
    required this.name,
    required this.type,
    this.thumbnailPath,
    this.intensityDefault = 0.5,
  });

  /// Factory constructor untuk mengubah data JSON
  /// menjadi objek FilterModel.
  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(

      // Mengambil ID filter dari JSON
      id: json['id'],

      // Mengambil nama filter
      name: json['name'],

      // Mengambil tipe filter.
      // Jika null maka menggunakan nilai default "color"
      type: json['type'] ?? 'color',

      // Mengambil path thumbnail
      thumbnailPath: json['thumbnail_path'],

      // Mengambil intensitas default.
      // Jika null maka menggunakan nilai 0.5
      intensityDefault: (json['intensity_default'] ?? 0.5).toDouble(),
    );
  }

  /// Mengubah objek FilterModel menjadi format JSON.
  /// Digunakan saat mengirim data ke backend.
  Map<String, dynamic> toJson() => {

        // Nama filter
        'name': name,

        // Jenis filter
        'type': type,

        // Path thumbnail filter
        'thumbnail_path': thumbnailPath,

        // Intensitas default filter
        'intensity_default': intensityDefault,
      };
}