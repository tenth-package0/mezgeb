import '../calendar/ethiopian_calendar.dart';

class VaultItem {
  const VaultItem({
    required this.id,
    required this.displayName,
    required this.mimeType,
    required this.encryptedFileName,
    required this.sizeBytes,
    required this.importedAt,
    required this.capturedAt,
  });

  final String id;
  final String displayName;
  final String mimeType;
  final String encryptedFileName;
  final int sizeBytes;
  final DateTime importedAt;
  final DateTime capturedAt;

  bool get isImage => mimeType.startsWith('image/');
  EthiopianDate get ethiopianDate =>
      EthiopianCalendar.fromGregorian(capturedAt);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'mime_type': mimeType,
      'encrypted_file_name': encryptedFileName,
      'size_bytes': sizeBytes,
      'imported_at': importedAt.millisecondsSinceEpoch,
      'captured_at': capturedAt.millisecondsSinceEpoch,
    };
  }

  static VaultItem fromMap(Map<String, Object?> map) {
    return VaultItem(
      id: map['id']! as String,
      displayName: map['display_name']! as String,
      mimeType: map['mime_type']! as String,
      encryptedFileName: map['encrypted_file_name']! as String,
      sizeBytes: map['size_bytes']! as int,
      importedAt: DateTime.fromMillisecondsSinceEpoch(
        map['imported_at']! as int,
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        map['captured_at']! as int,
      ),
    );
  }
}

class Album {
  const Album({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.itemCount,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int itemCount;
}

enum TimelineLevel { years, months, days }

enum TimelineMode { gallery, folders }
