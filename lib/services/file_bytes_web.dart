import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// record's web backend hands back a `blob:` URL as its "path" rather than
/// a real file — fetch() is the standard way to pull the bytes back out of
/// one of those in a browser.
Future<Uint8List?> readFileBytes(String path) async {
  try {
    final response = await web.window.fetch(path.toJS).toDart;
    final buffer = await response.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Blob URLs aren't real files to delete — revoking releases the browser
/// memory backing it instead.
Future<void> deleteFileQuietly(String path) async {
  try {
    web.URL.revokeObjectURL(path);
  } catch (_) {}
}
