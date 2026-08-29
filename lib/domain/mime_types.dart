import 'package:path/path.dart' as p;

abstract final class MimeTypes {
  static String fromFileName(String name) {
    return switch (p.extension(name).toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      '.pdf' => 'application/pdf',
      '.txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }
}
