import 'package:hive/hive.dart';
import '../models/history_model.dart';

/// Service untuk operasi CRUD pada box Hive history photobooth.
/// Box name: 'photobooth_history'
class HiveService {
  static const String _boxName = 'photobooth_history';

  /// Mendapatkan (atau membuka) box Hive untuk history.
  static Future<Box<HistoryModel>> get _box async =>
      await Hive.openBox<HistoryModel>(_boxName);

  // =================== CREATE ===================

  /// Menambahkan history baru ke box Hive.
  /// [history] adalah objek HistoryModel yang akan disimpan.
  /// Key otomatis menggunakan [history.id].
  static Future<void> addHistory(HistoryModel history) async {
    final box = await _box;
    await box.put(history.id, history);
  }

  // =================== READ ===================

  /// Mengambil semua history dari box Hive.
  /// Mengembalikan list HistoryModel yang diurutkan berdasarkan createdAt
  /// (paling baru di awal).
  static Future<List<HistoryModel>> getAllHistory() async {
    final box = await _box;
    final list = box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Mengambil satu history berdasarkan [id].
  static Future<HistoryModel?> getHistoryById(String id) async {
    final box = await _box;
    return box.get(id);
  }

  /// Mencari history berdasarkan keyword pada title.
  static Future<List<HistoryModel>> searchHistory(String keyword) async {
    final all = await getAllHistory();
    if (keyword.isEmpty) return all;
    final query = keyword.toLowerCase();
    return all.where((h) => h.title.toLowerCase().contains(query)).toList();
  }

  // =================== UPDATE ===================

  /// Memperbarui title/note dari history berdasarkan [id].
  /// [title] dan [note] bersifat opsional — hanya field yang diisi yang akan diupdate.
  static Future<void> updateHistory({
    required String id,
    String? title,
    String? note,
  }) async {
    final box = await _box;
    final existing = box.get(id);
    if (existing != null) {
      existing.title = title ?? existing.title;
      existing.note = note ?? existing.note;
      await existing.save();
    }
  }

  // =================== DELETE ===================

  /// Menghapus satu history berdasarkan [id].
  static Future<void> deleteHistory(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Menghapus semua history dari box (membersihkan seluruh riwayat).
  static Future<void> clearAllHistory() async {
    final box = await _box;
    await box.clear();
  }

  // =================== UTILITY ===================

  /// Mendapatkan jumlah total history yang tersimpan.
  static Future<int> getHistoryCount() async {
    final box = await _box;
    return box.length;
  }

  /// Menutup box (panggil saat aplikasi tidak lagi membutuhkan akses).
  static Future<void> closeBox() async {
    final box = await _box;
    await box.close();
  }
}

