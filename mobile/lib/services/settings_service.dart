import 'api_client.dart';
import '../models/app_settings_model.dart';

class SettingsService {
  static Future<AppSettingsModel> get() async {
    final res = await ApiClient.get('/settings');
    return AppSettingsModel.fromJson(res['data']);
  }

  static Future<AppSettingsModel> update(AppSettingsModel settings) async {
    final res = await ApiClient.put('/settings', settings.toJson());
    return AppSettingsModel.fromJson(res['data']);
  }
}
