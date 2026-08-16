import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fingerprint Unlock and Pattern Lock — Privacy & Security's on-device
/// app lock. Deliberately **not** part of AppState's Firestore-synced
/// blob: whether this app requires a fingerprint/pattern to open is a
/// question about *this device*, not account data that should follow
/// someone to a different phone. Everything here lives in local
/// SharedPreferences only, scoped per-account (by [uid]) so switching
/// accounts on a shared device doesn't inherit someone else's lock
/// settings — the same reasoning AppState's own local cache already uses.
///
/// The pattern is never stored in plain form, only its SHA-256 hash —
/// same principle as a password never being stored as typed.
class AppLockService {
  AppLockService(this.uid);

  final String uid;
  static final _localAuth = LocalAuthentication();

  String get _biometricKey => 'lumina_biometric_lock_$uid';
  String get _patternHashKey => 'lumina_pattern_hash_$uid';

  /// Whether the device itself is even capable of biometric auth — checks
  /// both "does this hardware support it" and "has the person actually
  /// enrolled a fingerprint/face," since a device can support the
  /// feature while having nothing enrolled yet. Explicitly false on web:
  /// local_auth has no web implementation, so guard it here rather than
  /// relying on the plugin to fail gracefully on its own.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }

  /// Triggers the OS's own fingerprint/face prompt. `biometricOnly: true`
  /// deliberately skips the OS's own PIN/pattern fallback — this app has
  /// its own Pattern Lock for that role, so falling back to the *device's*
  /// unlock method here would be a confusing, redundant second system.
  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Lumina',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

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

  /// Whether *any* lock method is currently active — main.dart's app-lock
  /// gate only ever shows up at all if this is true.
  Future<bool> isLockEnabled() async {
    final biometric = await isBiometricEnabled();
    final pattern = await hasPattern();
    return biometric || pattern;
  }
}
