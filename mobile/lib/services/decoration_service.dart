// Mengimpor ApiClient untuk melakukan request HTTP ke backend
import 'api_client.dart';

// Mengimpor model DecorationModel
import '../models/decoration_model.dart';

/// Service untuk mengelola data dekorasi (Decoration)
/// melalui API backend.
class DecorationService {

  /// Memperbarui data dekorasi berdasarkan ID.
  ///
  /// Parameter:
  /// - [id] : ID dekorasi yang akan diperbarui.
  /// - [data] : Data baru yang akan dikirim ke backend.
  static Future<DecorationModel> update(
      int id, Map<String, dynamic> data) async {

    // Mengirim request PUT ke endpoint sesuai ID dekorasi
    final res = await ApiClient.put('/decorations/$id', data);

    // Mengubah data JSON dari API menjadi objek DecorationModel
    return DecorationModel.fromJson(res['data']);
  }

  /// Menghapus data dekorasi berdasarkan ID.
  ///
  /// Parameter:
  /// - [id] : ID dekorasi yang akan dihapus.
  static Future<void> remove(int id) async {

    // Mengirim request DELETE ke endpoint sesuai ID dekorasi
    await ApiClient.delete('/decorations/$id');
  }
}