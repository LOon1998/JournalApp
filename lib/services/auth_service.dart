import 'package:firebase_auth/firebase_auth.dart';
import '../data/app_state.dart';
import 'cloud_sync_service.dart';

/// Thrown for any sign-up/sign-in/sign-out failure, with a message already
/// safe to show directly in the UI.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around FirebaseAuth — translates its exceptions into
/// [AuthException]s with plain-language messages, and exposes the pieces
/// the rest of the app actually needs (the current user, and a stream of
/// sign-in/sign-out changes to react to).
class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // One-shot signal, set by [signUp] and read (and cleared) once by
  // main.dart right after the auth-state stream picks up the new session —
  // that's what it uses to decide whether to show WelcomeScreen once
  // (brand-new account) rather than dropping straight into the app (a
  // returning sign-in). A plain static works fine here since there's only
  // ever one signed-out-to-signed-in transition to react to at a time, the
  // same one-shot-handoff pattern AppState already uses for pendingCheckIn.
  static bool _justSignedUp = false;

  static bool consumeJustSignedUp() {
    final value = _justSignedUp;
    _justSignedUp = false;
    return value;
  }

  // Same one-shot idea as [_justSignedUp], for the profile photo picked on
  // the sign-up screen — that screen exists entirely *before* there's a
  // uid (and therefore before an AppState to actually hold the photo)
  // exists, so it can't just call AppState.setProfilePhoto itself. Set
  // right before account creation (not after) so it's already in place no
  // matter how the authStateChanges stream and this method's remaining
  // awaits happen to interleave — see consumePendingAvatar's doc for what
  // reads it.
  static String? _pendingAvatarBase64;

  /// Consumed once by main.dart, right when building the AppState for a
  /// freshly-created account — null for every other case (returning
  /// sign-in, or a sign-up where no photo was picked).
  static String? consumePendingAvatar() {
    final value = _pendingAvatarBase64;
    _pendingAvatarBase64 = null;
    return value;
  }

  /// Fires whenever the signed-in user changes (including at app start,
  /// once Firebase has restored whatever session was already active) —
  /// this is what main.dart listens to, to decide whether to show the
  /// auth screen or the app itself.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({required String email, required String password, String? avatarBase64}) async {
    _pendingAvatarBase64 = avatarBase64;
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      _justSignedUp = true;
    } on FirebaseAuthException catch (e) {
      _pendingAvatarBase64 = null;
      throw AuthException(_message(e));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Permanently deletes the signed-in account and its data. Order
  /// matters: re-auth first (fails fast, nothing destructive yet if the
  /// password's wrong), then the Firestore data (needs a still-valid,
  /// matching request.auth to pass firestore.rules, so it has to happen
  /// *before* the Auth account is gone — and its failure isn't swallowed,
  /// since silently deleting the account while leaving journal data
  /// behind would make "permanently removed" a lie), then the local
  /// cache, and only then the Auth account itself — that last step is
  /// also what signs them out, so the app's own auth-state listener
  /// takes it from there.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No signed-in account to delete.');
    }
    final uid = user.uid;

    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_reauthMessage(e));
    }

    try {
      await CloudSyncService().delete(uid);
    } catch (_) {
      throw const AuthException("Couldn't delete your data — check your connection and try again.");
    }

    await AppState.clearLocalCache(uid);

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  /// Changes the signed-in account's password — re-auth first, same
  /// reasoning as [deleteAccount]: fails fast on a wrong current password
  /// before anything changes, and a stale session can't silently succeed.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No signed-in account.');
    }
    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_reauthMessage(e));
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  /// Same idea as [_message], but for re-authentication failures on
  /// screens that only ever collect a password (Change Password, Delete
  /// Account) — the person is already signed in, so their email was never
  /// re-entered here, and "Incorrect email or password" would be
  /// confusing on a form with no email field to have gotten wrong.
  String _reauthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Incorrect password.';
      default:
        return _message(e);
    }
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email — try signing in instead.';
      case 'invalid-email':
        return "That doesn't look like a valid email address.";
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'password-does-not-meet-requirements':
        return 'That password is too long — try something shorter.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts — try again in a few minutes.';
      case 'requires-recent-login':
        return 'For your security, please log out and sign in again before deleting your account.';
      case 'network-request-failed':
        return 'Could not reach the server — check your connection and try again.';
      default:
        return "Something went wrong — try again in a moment.";
    }
  }
}
