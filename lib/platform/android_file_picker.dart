import 'package:flutter/services.dart';

class PickedVaultFile {
  const PickedVaultFile({
    required this.name,
    required this.bytes,
    this.mimeType,
    this.uri,
    this.capturedAt,
  });

  final String name;
  final Uint8List bytes;
  final String? mimeType;
  final String? uri;
  final DateTime? capturedAt;
}

class AndroidFilePicker {
  static const _channel = MethodChannel('mezgeb/picker');
  static const _pickPhotosMethod = 'pickPhotos';
  static const _pickFilesMethod = 'pickFiles';
  static const _deleteOriginalMethod = 'deleteOriginal';

  static Future<List<PickedVaultFile>> pickPhotos() async {
    final raw = await _channel.invokeListMethod<Object?>(_pickPhotosMethod);
    return _mapPickedFiles(raw);
  }

  static Future<List<PickedVaultFile>> pickFiles() async {
    final raw = await _channel.invokeListMethod<Object?>(_pickFilesMethod);
    return _mapPickedFiles(raw);
  }

  static List<PickedVaultFile> _mapPickedFiles(List<Object?>? raw) {
    if (raw == null) return [];
    return raw
        .map((entry) => _mapPickedFile(entry! as Map<Object?, Object?>))
        .toList();
  }

  static PickedVaultFile _mapPickedFile(Map<Object?, Object?> map) {
    return PickedVaultFile(
      name: map['name']! as String,
      mimeType: map['mimeType'] as String?,
      uri: map['uri'] as String?,
      capturedAt: _mapDateTime(map['capturedAtMillis']),
      bytes: map['bytes']! as Uint8List,
    );
  }

  static DateTime? _mapDateTime(Object? value) {
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static Future<void> deleteOriginal(String uri) async {
    await _channel.invokeMethod<void>(_deleteOriginalMethod, {'uri': uri});
  }
}
