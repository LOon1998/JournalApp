import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pattern Lock — Privacy & Security's on-device app lock. Deliberately
/// **not** part of AppState's Firestore-synced blob: whether this app
/// requires a pattern to open is a question about *this device*, not
/// account data that should follow someone to a different phone.
/// Everything here lives in local SharedPreferences only, scoped
/// per-account (by [uid]) so switching accounts on a shared device
/// doesn't inherit someone else's lock settings — the same reasoning
/// AppState's own local cache already uses.
///
/// The pattern is never stored in plain form, only its SHA-256 hash —
/// same principle as a password never being stored as typed.
class AppLockService {
  AppLockService(this.uid);

  final String uid;

  String get _patternHashKey => 'lumina_pattern_hash_$uid';

  Future<bool> hasPattern() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patternHashKey) != null;
  }

  Future<void> setPattern(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patternHashKey, _hash(pattern));
  }

  Future<void> clearPattern() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patternHashKey);
  }

  Future<bool> verifyPattern(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_patternHashKey);
    return stored != null && stored == _hash(pattern);
  }

  String _hash(List<int> pattern) => sha256.convert(utf8.encode(pattern.join(','))).toString();

  /// Whether the lock is currently active — main.dart's app-lock gate
  /// only ever shows up at all if this is true.
  Future<bool> isLockEnabled() => hasPattern();
}

/// Marks an *expected* trip out of the app's own foreground — launching
/// the camera, the share sheet, a browser link, system settings, ... —
/// so main.dart's re-lock-on-backgrounding logic can tell that apart from
/// someone actually leaving the app to go do something else. Both cases
/// look identical to Flutter's own AppLifecycleState (paused/inactive
/// either way — there's no separate "we caused this" signal built in),
/// so without this, taking a profile photo (which launches the camera as
/// a separate Activity, backgrounding this one exactly the same way
/// switching to another app would) re-locked the app the instant it
/// returned — every real app with a lock screen (banking apps, password
/// managers, ...) treats a self-triggered interruption like this as still
/// "inside" the app, only re-locking on a genuine backgrounding.
///
/// A depth counter, not a one-shot flag — that was the original design
/// and it re-broke the camera case: Samsung's own camera app doesn't
/// always background-and-return in a single clean pause/resume pair. Its
/// internal photo-confirm screen can briefly resume this app's process
/// before pausing it again, producing a *second* leaving-foreground
/// transition while [pickPhotoAsBase64]/[pickAvatarAsBase64] is still
/// mid-await. A flag consumed by the first transition left that second
/// one looking like a genuine backgrounding, which is exactly what still
/// re-locked the app while taking a profile photo even with the old
/// guard in place. [begin] must be paired with [end] once the whole
/// operation's own Future finishes (a try/finally around the call, not
/// just the moment it launches) — [isActive] then stays true across
/// however many transitions happen in between, not just the first.
class ExternalActivityGuard {
  ExternalActivityGuard._();

  static int _depth = 0;
  static Timer? _safetyTimer;

  static void begin() {
    _depth++;
    // Safety net: if some caller's [end] is never reached (an exception
    // that skips a try/finally somehow, a Future that's dropped instead
    // of awaited), this stops the guard from staying "active" forever and
    // silently disabling relock-on-genuine-backgrounding for the rest of
    // the session. Comfortably longer than any real camera/gallery/share/
    // browser/settings round trip should ever take.
    _safetyTimer?.cancel();
    _safetyTimer = Timer(const Duration(seconds: 30), () => _depth = 0);
  }

  static void end() {
    if (_depth > 0) _depth--;
    if (_depth == 0) _safetyTimer?.cancel();
  }

  /// True while at least one expected external activity is still in
  /// flight. Doesn't consume or reset anything — see [begin]'s own doc
  /// for why a leaving-foreground transition needs to keep reading this
  /// as true for as long as the operation is still in flight, not just
  /// the first time it's checked.
  static bool get isActive => _depth > 0;
}
