/// ======================================================================
/// FrameModel
/// ======================================================================
///
/// Class ini merupakan model (representasi data) untuk sebuah Frame
/// pada aplikasi BloomBooth.
///
/// Model digunakan sebagai penghubung antara data yang diterima dari
/// backend (JSON) dengan object Dart yang digunakan di dalam aplikasi.
///
/// Selain itu, class ini juga dapat mengubah object Dart kembali
/// menjadi format JSON ketika data akan dikirim ke backend.
class FrameModel {

  /// ID unik dari frame.
  ///
  /// Nilai ini biasanya berasal dari database backend.
  final int id;

  /// Nama frame yang akan ditampilkan pada aplikasi.
  ///
  /// Contoh:
  /// - Classic
  /// - Birthday
  /// - Korean Style
  final String name;

  /// Jenis atau tipe layout frame.
  ///
  /// Contohnya:
  /// - 4-cut
  /// - 2-cut
  /// - landscape
  /// - portrait
  final String layoutType;

  /// Lokasi (path) gambar thumbnail frame.
  ///
  /// Nilai ini bersifat nullable (boleh kosong/null)
  /// apabila frame belum memiliki thumbnail.
  final String? thumbnailPath;

  /// Status apakah frame masih aktif atau tidak.
  ///
  /// true  = frame dapat digunakan.
  /// false = frame dinonaktifkan.
  final bool isActive;

  /// ==================================================================
  /// Constructor
  /// ==================================================================
  ///
  /// Constructor digunakan untuk membuat object FrameModel.
  ///
  /// Field id, name, dan layoutType wajib diisi.
  ///
  /// thumbnailPath bersifat opsional.
  ///
  /// isActive secara default bernilai true apabila
  /// tidak diberikan nilai.
  FrameModel({
    required this.id,
    required this.name,
    required this.layoutType,
    this.thumbnailPath,
    this.isActive = true,
  });

  /// ==================================================================
  /// Factory Constructor fromJson()
  /// ==================================================================
  ///
  /// Digunakan untuk mengubah data JSON yang diterima dari backend
  /// menjadi object FrameModel.
  ///
  /// Contoh JSON:
  ///
  /// {
  ///   "id":1,
  ///   "name":"Classic",
  ///   "layout_type":"4-cut",
  ///   "thumbnail_path":"classic.png",
  ///   "is_active":1
  /// }
  factory FrameModel.fromJson(Map<String, dynamic> json) {

    // Mengembalikan object FrameModel
    // berdasarkan data JSON.
    return FrameModel(

      // Mengambil ID frame.
      id: json['id'],

      // Mengambil nama frame.
      name: json['name'],

      // Mengambil jenis layout.
      //
      // Jika backend tidak mengirimkan nilai,
      // maka secara default menggunakan "4-cut".
      layoutType: json['layout_type'] ?? '4-cut',

      // Mengambil path thumbnail.
      thumbnailPath: json['thumbnail_path'],

      // Backend biasanya mengirim nilai:
      //
      // 1 = aktif
      // 0 = tidak aktif
      //
      // Nilai tersebut diubah menjadi boolean.
      isActive: (json['is_active'] ?? 1) == 1,
    );
  }

  /// ==================================================================
  /// Method toJson()
  /// ==================================================================
  ///
  /// Digunakan untuk mengubah object FrameModel
  /// menjadi format JSON.
  ///
  /// Method ini biasanya digunakan ketika aplikasi
  /// mengirim data ke backend melalui API
  /// (POST atau PUT Request).
  Map<String, dynamic> toJson() => {

        // Nama frame.
        'name': name,

        // Jenis layout frame.
        'layout_type': layoutType,

        // Lokasi thumbnail frame.
        'thumbnail_path': thumbnailPath,
      };
}