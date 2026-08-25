import 'package:shared_preferences/shared_preferences.dart';

/// The device's remembered UI language preference — separate from
/// [AppState.languageCode], which is tied to whichever account happens
/// to be signed in and is gone the moment they sign out. Without this,
/// signing out silently dropped back to the Auth screen in whatever
/// language the *device's own system settings* happen to be in,
/// regardless of the language someone had actually picked in Settings
/// while signed in — a real, reported mismatch, not just a cosmetic gap.
class DeviceLanguage {
  DeviceLanguage._();

  static const _prefsKey = 'device_language_code';

  /// In-memory cache — read synchronously by main.dart's pre-sign-in
  /// branch (no FutureBuilder/async gap needed mid-tree) and kept in
  /// sync by [set] whenever it changes. Only meaningful after [load]
  /// has completed once at startup.
  static String? _cached;

  static String? get current => _cached;

  /// Reads the persisted value once — awaited in main() before runApp,
  /// so it's already available for the very first build.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cached = prefs.getString(_prefsKey);
    } catch (_) {
      // Best-effort — falls back to the device's own system locale, same
      // as if nothing had ever been chosen (see main.dart).
    }
  }

  /// Called from AppState.setLanguageCode (a real choice made while
  /// signed in) and from AppState._restore (an existing choice synced
  /// down from the cloud on a device that's never set one locally) — so
  /// either way, signing out later in the *same* session already
  /// reflects it, not just after the next full app restart.
  static Future<void> set(String? code) async {
    if (_cached == code) return;
    _cached = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, code);
      }
    } catch (_) {
      // Best-effort — the in-memory cache above is already updated
      // regardless, so this process's own auth screen still gets it
      // right even if the write itself silently failed.
    }
  }
}
