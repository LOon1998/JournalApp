import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_lock_service.dart';

/// Bridges Android's own screenshot-taken signal (MainActivity.kt's
/// registerScreenCaptureCallback, API 34+ only) into ExternalActivityGuard,
/// so Pattern Lock can tell "a screenshot was just taken" apart from an
/// actual app switch with certainty, rather than relying purely on
/// main.dart's own timing-based debounce for it — that debounce is still
/// what every older-than-Android-14 device falls back to, since there's
/// no equivalent OS signal to bridge there.
class ScreenshotGuard {
  ScreenshotGuard._();

  static const _channel = MethodChannel('com.lumina.lumina/screenshot');
  static bool _initialized = false;

  /// Call once, early (main.dart's own main()) — safe to call more than
  /// once, and a no-op on web/anywhere other than the Android channel
  /// above actually exists.
  static void ensureInitialized() {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'screenshotTaken') {
        // Covers not just the instant of capture but the few seconds
        // Samsung's own Smart Capture toolbar (edit/share/scroll-capture)
        // typically stays open afterward, which can itself keep briefly
        // stealing and returning focus the same way switching away to
        // another app does.
        ExternalActivityGuard.begin();
        Future.delayed(const Duration(seconds: 3), ExternalActivityGuard.end);
      }
    });
  }
}
