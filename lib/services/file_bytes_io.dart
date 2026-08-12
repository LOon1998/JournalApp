import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFileBytes(String path) async {
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> deleteFileQuietly(String path) async {
  try {
    await File(path).delete();
  } catch (_) {
    // Best-effort cleanup of a temp recording file — not worth surfacing.
  }
}
