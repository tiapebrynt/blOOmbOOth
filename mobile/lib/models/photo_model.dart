class PhotoModel {
  final int id;
  final int sessionId;
  final int? filterId;
  final String imagePath;
  final int orderIndex;
  final double beautySmooth;
  final double beautyBrighten;
  final String? filterName;
  final String? filterType;

  PhotoModel({
    required this.id,
    required this.sessionId,
    this.filterId,
    required this.imagePath,
    this.orderIndex = 0,
    this.beautySmooth = 0,
    this.beautyBrighten = 0,
    this.filterName,
    this.filterType,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'],
      sessionId: json['session_id'],
      filterId: json['filter_id'],
      imagePath: json['image_path'],
      orderIndex: json['order_index'] ?? 0,
      beautySmooth: (json['beauty_smooth'] ?? 0).toDouble(),
      beautyBrighten: (json['beauty_brighten'] ?? 0).toDouble(),
      filterName: json['filter_name'],
      filterType: json['filter_type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'filter_id': filterId,
        'image_path': imagePath,
        'order_index': orderIndex,
        'beauty_smooth': beautySmooth,
        'beauty_brighten': beautyBrighten,
      };
}
