import 'package:hive/hive.dart';

/// Model data untuk riwayat (history) photobooth yang disimpan di Hive lokal.
class HistoryModel extends HiveObject {
  String id;
  String imagePath;
  String title;
  String createdAt;
  String? note;

  HistoryModel({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.createdAt,
    this.note,
  });

  /// Konversi dari Map (misal dari JSON API)
  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: map['image_path'] ?? '',
      title: map['title'] ?? 'Untitled',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      note: map['note'],
    );
  }

  /// Konversi ke Map (untuk dikirim ke API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'title': title,
      'created_at': createdAt,
      'note': note,
    };
  }

  /// CopyWith untuk update sebagian field
  HistoryModel copyWith({
    String? id,
    String? imagePath,
    String? title,
    String? createdAt,
    String? note,
  }) {
    return HistoryModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}

/// TypeAdapter manual untuk menyimpan HistoryModel ke Hive.
/// Tidak perlu build_runner — adapter ini didaftarkan manual di main().
class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final int typeId = 0;

  @override
  HistoryModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryModel(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      title: fields[2] as String,
      createdAt: fields[3] as String,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.imagePath);
    writer.writeByte(2);
    writer.write(obj.title);
    writer.writeByte(3);
    writer.write(obj.createdAt);
    writer.writeByte(4);
    writer.write(obj.note);
  }
}

