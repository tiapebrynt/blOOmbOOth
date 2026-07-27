/// Model yang merepresentasikan data Decoration.
/// Digunakan untuk menyimpan informasi dekorasi
/// seperti sticker, teks, atau emoji yang ditempel pada hasil foto.
class DecorationModel {

  /// ID unik dekorasi
  final int id;

  /// ID sesi photobooth yang memiliki dekorasi ini
  final int sessionId;

  /// Jenis dekorasi
  /// Contoh:
  /// - sticker
  /// - text
  /// - emoji
  final String type;

  /// Isi dekorasi.
  /// Bisa berupa teks, emoji, atau path gambar sticker.
  final String content;

  /// Posisi dekorasi pada sumbu X
  final double posX;

  /// Posisi dekorasi pada sumbu Y
  final double posY;

  /// Skala (ukuran) dekorasi
  final double scale;

  /// Rotasi dekorasi dalam derajat
  final double rotation;

  /// Constructor untuk membuat objek DecorationModel
  DecorationModel({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.content,
    this.posX = 0,
    this.posY = 0,
    this.scale = 1,
    this.rotation = 0,
  });

  /// Factory constructor untuk mengubah data JSON
  /// dari backend menjadi objek DecorationModel.
  factory DecorationModel.fromJson(Map<String, dynamic> json) {
    return DecorationModel(

      // Mengambil ID dekorasi
      id: json['id'],

      // Mengambil ID sesi photobooth
      sessionId: json['session_id'],

      // Mengambil jenis dekorasi.
      // Jika null maka menggunakan nilai default "sticker"
      type: json['type'] ?? 'sticker',

      // Mengambil isi dekorasi
      content: json['content'],

      // Mengambil posisi X
      posX: (json['pos_x'] ?? 0).toDouble(),

      // Mengambil posisi Y
      posY: (json['pos_y'] ?? 0).toDouble(),

      // Mengambil nilai skala dekorasi
      scale: (json['scale'] ?? 1).toDouble(),

      // Mengambil nilai rotasi dekorasi
      rotation: (json['rotation'] ?? 0).toDouble(),
    );
  }

  /// Mengubah objek DecorationModel menjadi format JSON.
  /// Digunakan saat mengirim data ke backend.
  Map<String, dynamic> toJson() => {

        // Jenis dekorasi
        'type': type,

        // Isi dekorasi
        'content': content,

        // Posisi X dekorasi
        'pos_x': posX,

        // Posisi Y dekorasi
        'pos_y': posY,

        // Skala dekorasi
        'scale': scale,

        // Rotasi dekorasi
        'rotation': rotation,
      };
}