// Mengimpor ApiClient.
// ApiClient merupakan class yang digunakan untuk melakukan komunikasi
// dengan backend melalui HTTP Request seperti GET, POST, PUT, dan DELETE.
import 'api_client.dart';

// Mengimpor model FrameModel.
// Model ini digunakan untuk merepresentasikan data frame
// dalam bentuk object Dart.
import '../models/frame_model.dart';

/// ======================================================================
/// FrameService
/// ======================================================================
///
/// Class ini berfungsi sebagai penghubung antara aplikasi Flutter
/// dengan API Backend yang menangani data Frame.
///
/// Seluruh operasi CRUD (Create, Read, Update, Delete)
/// terhadap data frame dilakukan melalui class ini.
///
/// Operasi yang tersedia:
/// - getAll()   -> Mengambil seluruh data frame.
/// - getOne()   -> Mengambil satu data frame berdasarkan ID.
/// - create()   -> Menambahkan frame baru.
/// - update()   -> Mengubah data frame.
/// - remove()   -> Menghapus data frame.
class FrameService {

  /// ==================================================================
  /// Mengambil Seluruh Data Frame
  /// ==================================================================
  ///
  /// Fungsi ini mengirim HTTP GET Request ke endpoint:
  ///
  ///     /frames
  ///
  /// Backend akan mengembalikan daftar seluruh frame
  /// dalam format JSON.
  static Future<List<FrameModel>> getAll() async {

    // Mengirim request GET ke endpoint "/frames".
    final res = await ApiClient.get('/frames');

    // Mengambil bagian "data" dari response,
    // kemudian mengubah setiap object JSON
    // menjadi object FrameModel.
    return (res['data'] as List)
        .map((e) => FrameModel.fromJson(e))
        .toList();
  }

  /// ==================================================================
  /// Mengambil Satu Data Frame
  /// ==================================================================
  ///
  /// Fungsi ini mengambil satu data frame berdasarkan ID.
  ///
  /// Contoh endpoint:
  ///
  ///     /frames/1
  static Future<FrameModel> getOne(int id) async {

    // Mengirim request GET berdasarkan ID frame.
    final res = await ApiClient.get('/frames/$id');

    // Mengubah response JSON menjadi object FrameModel.
    return FrameModel.fromJson(res['data']);
  }

  /// ==================================================================
  /// Menambahkan Data Frame Baru
  /// ==================================================================
  ///
  /// Fungsi ini mengirim HTTP POST Request
  /// untuk menambahkan data frame baru ke backend.
  static Future<FrameModel> create(FrameModel frame) async {

    // Mengirim data frame dalam bentuk JSON
    // ke endpoint "/frames".
    final res = await ApiClient.post(
      '/frames',
      frame.toJson(),
    );

    // Response dari backend diubah kembali
    // menjadi object FrameModel.
    return FrameModel.fromJson(res['data']);
  }

  /// ==================================================================
  /// Memperbarui Data Frame
  /// ==================================================================
  ///
  /// Fungsi ini mengubah data frame berdasarkan ID.
  ///
  /// Backend menggunakan HTTP PUT Request.
  static Future<FrameModel> update(
      int id,
      FrameModel frame,
      ) async {

    // Mengirim data frame yang telah diperbarui
    // ke endpoint berdasarkan ID.
    final res = await ApiClient.put(
      '/frames/$id',
      frame.toJson(),
    );

    // Mengubah response JSON menjadi object FrameModel.
    return FrameModel.fromJson(res['data']);
  }

  /// ==================================================================
  /// Menghapus Data Frame
  /// ==================================================================
  ///
  /// Fungsi ini menghapus data frame berdasarkan ID.
  ///
  /// Backend menggunakan HTTP DELETE Request.
  static Future<void> remove(int id) async {

    // Mengirim request DELETE ke endpoint
    // sesuai ID frame yang akan dihapus.
    await ApiClient.delete('/frames/$id');
  }
}