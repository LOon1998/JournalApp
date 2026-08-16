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
