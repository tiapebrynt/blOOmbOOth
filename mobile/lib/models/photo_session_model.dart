import 'photo_model.dart';
import 'decoration_model.dart';
// ahnaf
class PhotoSessionModel {
  final int id;
  final int userId;
  final int? frameId;
  final String title;
  final String layoutType;
  final bool isFavorite;
  final String createdAt;
  final String? frameName;
  final String? frameThumbnail;
  final String? firstPhotoPath;
  final List<PhotoModel> photos;
  final List<DecorationModel> decorations;

  PhotoSessionModel({
    required this.id,
    required this.userId,
    this.frameId,
    required this.title,
    required this.layoutType,
    this.isFavorite = false,
    required this.createdAt,
    this.frameName,
    this.frameThumbnail,
    this.firstPhotoPath,
    this.photos = const [],
    this.decorations = const [],
  });

  factory PhotoSessionModel.fromJson(Map<String, dynamic> json) {
    return PhotoSessionModel(
      id: json['id'],
      userId: json['user_id'],
      frameId: json['frame_id'],
      title: json['title'] ?? 'Untitled Strip',
      layoutType: json['layout_type'] ?? '4-cut',
      isFavorite: (json['is_favorite'] ?? 0) == 1,
      createdAt: json['created_at'] ?? '',
      frameName: json['frame_name'],
      frameThumbnail: json['frame_thumbnail'],
      firstPhotoPath: json['first_photo_path'],
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => PhotoModel.fromJson(p)).toList()
          : const [],
      decorations: json['decorations'] != null
          ? (json['decorations'] as List)
              .map((d) => DecorationModel.fromJson(d))
              .toList()
          : const [],
    );
  }
}
