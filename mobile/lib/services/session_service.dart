import 'api_client.dart';
import '../models/photo_session_model.dart';
import '../models/photo_model.dart';
import '../models/decoration_model.dart';

class SessionService {
  // My Gallery: daftar semua strip milik user login
  static Future<List<PhotoSessionModel>> getAll() async {
    final res = await ApiClient.get('/sessions');
    return (res['data'] as List)
        .map((e) => PhotoSessionModel.fromJson(e))
        .toList();
  }

  // Strip Detail: satu strip lengkap dengan foto & dekorasinya
  static Future<PhotoSessionModel> getOne(int id) async {
    final res = await ApiClient.get('/sessions/$id');
    return PhotoSessionModel.fromJson(res['data']);
  }

  // Final Preview -> Simpan ke My Gallery
  static Future<PhotoSessionModel> create({
    int? frameId,
    required String title,
    required String layoutType,
    List<PhotoModel> photos = const [],
  }) async {
    final res = await ApiClient.post('/sessions', {
      'frame_id': frameId,
      'title': title,
      'layout_type': layoutType,
      'photos': photos.map((p) => p.toJson()).toList(),
    });
    return PhotoSessionModel.fromJson(res['data']);
  }

  // Decorate Strip: update judul/frame/favorit
  static Future<PhotoSessionModel> update(
    int id, {
    String? title,
    int? frameId,
    bool? isFavorite,
  }) async {
    final res = await ApiClient.put('/sessions/$id', {
      if (title != null) 'title': title,
      if (frameId != null) 'frame_id': frameId,
      if (isFavorite != null) 'is_favorite': isFavorite ? 1 : 0,
    });
    return PhotoSessionModel.fromJson(res['data']);
  }

  // Hapus strip dari My Gallery
  static Future<void> remove(int id) async {
    await ApiClient.delete('/sessions/$id');
  }

  // Tambah foto baru ke strip yang sudah ada (mis. retake dari Live Camera)
  static Future<PhotoModel> addPhoto(int sessionId, PhotoModel photo) async {
    final res = await ApiClient.post('/sessions/$sessionId/photos', photo.toJson());
    return PhotoModel.fromJson(res['data']);
  }

  // Decorate Strip: tambah stiker/teks/emoji
  static Future<DecorationModel> addDecoration(
    int sessionId,
    DecorationModel decoration,
  ) async {
    final res = await ApiClient.post(
      '/sessions/$sessionId/decorations',
      decoration.toJson(),
    );
    return DecorationModel.fromJson(res['data']);
  }
}
