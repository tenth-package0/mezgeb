import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart';
import '../domain/mime_types.dart';
import '../platform/android_file_picker.dart';
import '../security/security_service.dart';
import 'vault_database.dart';

class VaultRepository {
  VaultRepository({required this.database, required this.security});

  final VaultDatabase database;
  final SecurityService security;
  final _cipher = AesGcm.with256bits();

  Future<List<VaultItem>> loadItems() => database.loadItems();
  Future<List<VaultItem>> loadItemsForAlbum(String albumId) {
    return database.loadItemsForAlbum(albumId);
  }

  Future<List<Album>> loadAlbums() => database.loadAlbums();
  Future<List<Album>> loadAlbumsForItem(String itemId) {
    return database.loadAlbumsForItem(itemId);
  }

  Future<void> importPickedFiles({
    required List<PickedVaultFile> files,
    required bool deleteOriginals,
  }) async {
    for (final file in files) {
      final bytes = file.bytes;
      final now = DateTime.now();
      final capturedAt = file.capturedAt ?? now;
      final id = _newId();
      final encryptedFileName = '$id.mezgeb';
      await _writeEncryptedFile(encryptedFileName, bytes);
      await database.insertItem(
        VaultItem(
          id: id,
          displayName: file.name,
          mimeType: file.mimeType ?? MimeTypes.fromFileName(file.name),
          encryptedFileName: encryptedFileName,
          sizeBytes: bytes.length,
          importedAt: now,
          capturedAt: capturedAt,
        ),
      );

      if (deleteOriginals && file.uri != null) {
        // Android may deny deletion for provider-backed documents; import success wins.
        await AndroidFilePicker.deleteOriginal(file.uri!);
      }
    }
  }

  Future<Uint8List> decryptItem(VaultItem item) async {
    final file = File(
      p.join(await _vaultDirectoryPath(), item.encryptedFileName),
    );
    final packed = await file.readAsBytes();
    final nonceLength = packed[0];
    final macLength = packed[1];
    final nonce = packed.sublist(2, 2 + nonceLength);
    final macStart = 2 + nonceLength;
    final mac = Mac(packed.sublist(macStart, macStart + macLength));
    final cipherText = packed.sublist(macStart + macLength);
    final clearBytes = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: await security.fileSecretKey(),
    );
    return Uint8List.fromList(clearBytes);
  }

  Future<void> deleteItem(VaultItem item) async {
    await database.deleteItem(item.id);
    final file = File(
      p.join(await _vaultDirectoryPath(), item.encryptedFileName),
    );
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteItems(Iterable<VaultItem> items) async {
    for (final item in items) {
      await deleteItem(item);
    }
  }

  Future<void> createAlbum(String name) async {
    await database.createAlbum(
      Album(
        id: _newId(),
        name: name.trim(),
        createdAt: DateTime.now(),
        itemCount: 0,
      ),
    );
  }

  Future<void> deleteAlbum(String albumId) => database.deleteAlbum(albumId);

  Future<void> addItemToAlbum(String itemId, String albumId) {
    return database.addItemToAlbum(itemId, albumId);
  }

  Future<void> moveItemToAlbum(String itemId, String albumId) {
    return database.moveItemToAlbum(itemId, albumId);
  }

  Future<int> storageUsedBytes() async {
    final dir = Directory(await _vaultDirectoryPath());
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> _writeEncryptedFile(String fileName, Uint8List bytes) async {
    final box = await _cipher.encrypt(
      bytes,
      secretKey: await security.fileSecretKey(),
    );
    final packed = Uint8List.fromList([
      box.nonce.length,
      box.mac.bytes.length,
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ]);
    final file = File(p.join(await _vaultDirectoryPath(), fileName));
    await file.writeAsBytes(packed, flush: true);
  }

  Future<String> _vaultDirectoryPath() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'vault_items'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  String _newId() {
    final random = Random.secure().nextInt(1 << 32);
    return '${DateTime.now().microsecondsSinceEpoch}_$random';
  }
}
