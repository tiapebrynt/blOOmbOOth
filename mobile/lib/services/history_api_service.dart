import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/history_model.dart';
import '../utils/constants.dart';

/// Service untuk sinkronisasi data history dengan backend server.
///
/// Menggunakan package `http` (yang sudah ada) untuk berkomunikasi
/// dengan REST API backend. Base URL diambil dari [AppConstants.baseUrl].
class HistoryApiService {
  static const _headers = {'Content-Type': 'application/json'};

  /// Mengirim satu history baru ke backend server.
  ///
  /// [history] adalah objek HistoryModel yang akan dikirim.
  /// Mengembalikan response dari server sebagai Map.
  static Future<Map<String, dynamic>> syncToServer(HistoryModel history) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/history');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(history.toMap()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal sinkronisasi ke server: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Mengirim beberapa history sekaligus ke backend (batch sync).
  ///
  /// [historyList] adalah list HistoryModel yang akan dikirim.
  /// Mengembalikan response dari server sebagai Map.
  static Future<Map<String, dynamic>> syncBatchToServer(
      List<HistoryModel> historyList) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/history/batch');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'data': historyList.map((h) => h.toMap()).toList(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal batch sync ke server: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Mengambil semua data history dari backend server.
  ///
  /// Mengembalikan list HistoryModel yang diterima dari server.
  /// Gunakan method ini untuk menyinkronkan data dari server ke lokal.
  static Future<List<HistoryModel>> fetchFromServer() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/history');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> dataList = body['data'] ?? body['history'] ?? [];

      return dataList
          .map((item) => HistoryModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Gagal mengambil data dari server: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Mengupdate satu history di backend.
  ///
  /// [id] adalah ID history yang akan diupdate.
  /// [history] adalah data baru yang akan dikirim.
  static Future<Map<String, dynamic>> updateOnServer(
      String id, HistoryModel history) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/history/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(history.toMap()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal mengupdate data di server: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Menghapus satu history dari backend.
  ///
  /// [id] adalah ID history yang akan dihapus.
  static Future<Map<String, dynamic>> deleteOnServer(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/history/$id');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal menghapus data di server: ${response.statusCode} ${response.body}',
      );
    }
  }
}

