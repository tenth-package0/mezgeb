import 'package:flutter_test/flutter_test.dart';
import 'package:mezgeb/domain/models.dart';

void main() {
  test('vault items round-trip through database maps', () {
    final item = VaultItem(
      id: 'item-1',
      displayName: 'photo.jpg',
      mimeType: 'image/jpeg',
      encryptedFileName: 'item-1.mezgeb',
      sizeBytes: 2048,
      importedAt: DateTime.utc(2026, 1, 2),
      capturedAt: DateTime.utc(2025, 12, 31),
    );

    final restored = VaultItem.fromMap(item.toMap());

    expect(restored.id, item.id);
    expect(restored.displayName, item.displayName);
    expect(restored.mimeType, item.mimeType);
    expect(restored.encryptedFileName, item.encryptedFileName);
    expect(restored.sizeBytes, item.sizeBytes);
    expect(
      restored.importedAt.millisecondsSinceEpoch,
      item.importedAt.millisecondsSinceEpoch,
    );
    expect(
      restored.capturedAt.millisecondsSinceEpoch,
      item.capturedAt.millisecondsSinceEpoch,
    );
  });
}
