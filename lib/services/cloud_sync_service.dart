import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Reads/writes one person's entire app-state blob to Firestore, at
/// `users/{uid}/state/data` — see firestore.rules for why that path is
/// what actually keeps it private to them.
///
/// This mirrors the same "one JSON map, whole app state" shape AppState
/// already uses for its local SharedPreferences cache; Firestore here is
/// just a second (authoritative, cross-device) place that same map lives.
class CloudSyncService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('state').doc('data');

  /// Fetches the signed-in user's saved state, or null if they've never
  /// synced before (brand-new account) or the read fails (offline —
  /// callers should fall back to the local cache in that case).
  Future<Map<String, dynamic>?> fetch(String uid) async {
    try {
      final snap = await _doc(uid).get(const GetOptions(source: Source.server));
      final data = snap.data();
      // A document can exist in Firestore with zero fields (e.g. one that
      // had every field individually cleared) — that carries no more
      // useful information than "nothing saved yet" does, but treating it
      // as real cloud data would make AppState._restore trust this empty
      // map over a perfectly good local cache, resetting everything back
      // to defaults on every login instead of falling back correctly.
      return (data == null || data.isEmpty) ? null : data;
    } catch (e) {
      // Logged (not just silently swallowed) — this was completely
      // invisible before, which made a real sync failure indistinguishable
      // from "brand-new account, nothing saved yet" in practice.
      debugPrint('CloudSyncService.fetch($uid) failed: $e');
      return null;
    }
  }

  /// Overwrites the user's saved state with [data]. Best-effort — Firestore
  /// itself already queues writes locally and retries once back online, so
  /// a thrown/offline error here just means this particular push didn't
  /// get a chance to queue (e.g. mid-navigation-away); the local
  /// SharedPreferences cache is what keeps the app usable regardless.
  Future<void> push(String uid, Map<String, dynamic> data) async {
    try {
      await _doc(uid).set(data);
      debugPrint('CloudSyncService.push($uid): succeeded — userName=${data['userName']}, hasPhoto=${data['profilePhoto'] != null}');
    } catch (e) {
      // Logged (not just silently swallowed) — offline/best-effort is
      // still the right behavior (see doc comment above), but a *genuine*
      // failure (e.g. exceeding Firestore's 1MiB document size limit,
      // which this whole-app-state-in-one-doc/embedded-photos design can
      // realistically hit) was completely invisible before this.
      debugPrint('CloudSyncService.push($uid) failed: $e');
    }
  }

  /// Permanently removes the user's saved state — part of account
  /// deletion (see AuthService.deleteAccount). Unlike [push]/[fetch], this
  /// one is *not* swallowed on failure: deleting an account is a one-shot,
  /// user-initiated action that should surface an error rather than
  /// silently leave data behind while still deleting the auth account.
  Future<void> delete(String uid) => _doc(uid).delete();
}
