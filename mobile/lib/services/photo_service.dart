import 'api_client.dart';
import '../models/photo_model.dart';

class PhotoService {
  static Future<PhotoModel> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put('/photos/$id', data);
    return PhotoModel.fromJson(res['data']);
  }

  static Future<void> remove(int id) async {
    await ApiClient.delete('/photos/$id');
  }
}
