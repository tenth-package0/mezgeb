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
      idColumn: id,
      displayNameColumn: displayName,
      mimeTypeColumn: mimeType,
      encryptedFileNameColumn: encryptedFileName,
      sizeBytesColumn: sizeBytes,
      importedAtColumn: importedAt.millisecondsSinceEpoch,
      capturedAtColumn: capturedAt.millisecondsSinceEpoch,
    };
  }

  static VaultItem fromMap(Map<String, Object?> map) {
    return VaultItem(
      id: map[idColumn]! as String,
      displayName: map[displayNameColumn]! as String,
      mimeType: map[mimeTypeColumn]! as String,
      encryptedFileName: map[encryptedFileNameColumn]! as String,
      sizeBytes: map[sizeBytesColumn]! as int,
      importedAt: DateTime.fromMillisecondsSinceEpoch(
        map[importedAtColumn]! as int,
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        map[capturedAtColumn]! as int,
      ),
    );
  }

  static const idColumn = 'id';
  static const displayNameColumn = 'display_name';
  static const mimeTypeColumn = 'mime_type';
  static const encryptedFileNameColumn = 'encrypted_file_name';
  static const sizeBytesColumn = 'size_bytes';
  static const importedAtColumn = 'imported_at';
  static const capturedAtColumn = 'captured_at';
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
