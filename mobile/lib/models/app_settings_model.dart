class AppSettingsModel {
  final int id;
  final int userId;
  final String cameraResolution;
  final bool watermarkEnabled;
  final int countdownDuration;
  final bool liveEffectsEnabled;

  AppSettingsModel({
    required this.id,
    required this.userId,
    required this.cameraResolution,
    required this.watermarkEnabled,
    required this.countdownDuration,
    required this.liveEffectsEnabled,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      id: json['id'],
      userId: json['user_id'],
      cameraResolution: json['camera_resolution'] ?? '1080p',
      watermarkEnabled: (json['watermark_enabled'] ?? 1) == 1,
      countdownDuration: json['countdown_duration'] ?? 3,
      liveEffectsEnabled: (json['live_effects_enabled'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'camera_resolution': cameraResolution,
        'watermark_enabled': watermarkEnabled ? 1 : 0,
        'countdown_duration': countdownDuration,
        'live_effects_enabled': liveEffectsEnabled ? 1 : 0,
      };
}
