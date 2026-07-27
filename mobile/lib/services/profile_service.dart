import 'api_client.dart';
import '../models/user_model.dart';

/// Aplikasi ini tidak memakai login/register. Profil yang ditampilkan
/// di App Settings adalah profil default yang sudah otomatis tersedia
/// di backend (lihat backend/database/seed.js).
class ProfileService {
  static Future<UserModel> get() async {
    final res = await ApiClient.get('/profile');
    return UserModel.fromJson(res['data']);
  }

  static Future<UserModel> update({String? name}) async {
    final res = await ApiClient.put('/profile', {
      if (name != null) 'name': name,
    });
    return UserModel.fromJson(res['data']);
  }
}
