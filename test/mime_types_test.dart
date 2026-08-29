import 'package:flutter_test/flutter_test.dart';
import 'package:mezgeb/domain/mime_types.dart';

void main() {
  test('detects supported file types without case sensitivity', () {
    expect(MimeTypes.fromFileName('portrait.JPEG'), 'image/jpeg');
    expect(MimeTypes.fromFileName('document.PDF'), 'application/pdf');
    expect(MimeTypes.fromFileName('notes.txt'), 'text/plain');
  });

  test('uses a safe binary fallback for unknown extensions', () {
    expect(
      MimeTypes.fromFileName('archive.custom'),
      'application/octet-stream',
    );
  });
}
