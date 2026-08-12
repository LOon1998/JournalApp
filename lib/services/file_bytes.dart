/// Reads (and cleans up) a recorded audio file's bytes, from whichever
/// implementation is valid for the current platform — see
/// file_bytes_io.dart (used everywhere except web) vs file_bytes_web.dart.
library;

export 'file_bytes_io.dart' if (dart.library.js_interop) 'file_bytes_web.dart';
