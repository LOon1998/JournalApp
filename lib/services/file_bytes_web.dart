import 'dart:typed_data';

// `dart:io`'s File isn't available on web, and record's web implementation
// returns a blob URL as its "path" rather than a real file, so reading the
// recorded bytes back out isn't supported through this path on web yet —
// this stub keeps the app compiling for web (the GitHub Pages CI build)
// instead of failing outright. The app's actual target is mobile per how
// it's being tested, where file_bytes_io.dart's real implementation runs.
Future<Uint8List?> readFileBytes(String path) async => null;

Future<void> deleteFileQuietly(String path) async {}
