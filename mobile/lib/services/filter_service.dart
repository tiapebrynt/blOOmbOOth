// Mengimpor ApiClient untuk melakukan request HTTP ke backend
import 'api_client.dart';

// Mengimpor model FilterModel
import '../models/filter_model.dart';

/// Service untuk mengelola data filter melalui API
class FilterService {

  /// Mengambil seluruh data filter dari API.
  ///
  /// Parameter [type] bersifat opsional.
  /// Jika diisi, hanya filter dengan tipe tersebut yang akan diambil.
  static Future<List<FilterModel>> getAll({String? type}) async {

    // Menambahkan query parameter jika type tidak null
    final query = type != null ? '?type=$type' : '';

    // Mengirim request GET ke endpoint /filters
    final res = await ApiClient.get('/filters$query');

    // Mengubah data JSON menjadi List<FilterModel>
    return (res['data'] as List)
        .map((e) => FilterModel.fromJson(e))
        .toList();
  }

  /// Menambahkan data filter baru ke database melalui API.
  static Future<FilterModel> create(FilterModel filter) async {

    // Mengirim request POST beserta data filter
    final res = await ApiClient.post('/filters', filter.toJson());

    // Mengembalikan data filter yang berhasil dibuat
    return FilterModel.fromJson(res['data']);
  }

  /// Memperbarui data filter berdasarkan ID.
  static Future<FilterModel> update(int id, FilterModel filter) async {

    // Mengirim request PUT ke endpoint sesuai ID filter
    final res = await ApiClient.put('/filters/$id', filter.toJson());

    // Mengembalikan data filter yang telah diperbarui
    return FilterModel.fromJson(res['data']);
  }

  /// Menghapus data filter berdasarkan ID.
  static Future<void> remove(int id) async {

    // Mengirim request DELETE ke endpoint sesuai ID
    await ApiClient.delete('/filters/$id');
  }
}