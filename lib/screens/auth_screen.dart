import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/media_capture.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';

// Kept in sync with pubspec.yaml's own `version:` field by hand, same as
// about_screen.dart's own copy of this constant (see its doc comment for
// why this isn't read from package_info_plus at runtime instead, and for
// what the "(N)" is) — bump both together.
const _appVersion = '1.0.0 (54)';

// SharedPreferences key for "Remember me" — just the email, not the
// password. Session persistence across app restarts is already handled by
// Firebase Auth itself (defaults to persisting on Android/iOS), so this is
// purely a convenience to have the email field pre-filled next time
// someone signs in on this device, not what keeps them signed in.
const _rememberedEmailKey = 'lumina_remembered_email';

/// Shown whenever there's no signed-in Firebase user — sign in for
/// returning users, sign up for new ones, toggled by [_isSignUp]. Once
/// sign-in succeeds, main.dart's auth-state listener swaps this out for
/// the real app automatically; this screen doesn't navigate anywhere
/// itself.
///
/// Visual layout follows the Lumina web mockups' login/sign-up screens —
/// soft gradient-blob background, a FloatingCard-wrapped form, icon-led
/// pill inputs, and (sign-up only) a tappable profile-photo circle. Left
/// out from those mockups: the Google/Apple buttons — no OAuth provider
/// is wired up, email/password is the only method Firebase Auth is
/// configured for. The photo doesn't go through Firebase Storage (not
/// part of this setup) — it's base64-encoded and carried in the same
/// AppState blob everything else already syncs through, same as entry
/// photos already are.
///
/// Sign-in is by email only — a username-based alternative was tried and
/// then deliberately removed: enforcing unique usernames (and routing
/// sign-in through a lookup table to resolve one to an email) added real
/// ongoing complexity — collision handling at sign-up, an extra Firestore
/// collection with its own rules, a lookup on every sign-in — for a
/// convenience that email already covers.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  // Sign-in only (see _rememberedEmailKey's doc comment). Defaults to on —
  // pre-filling the email is the friendlier default, and unchecking it is
  // one tap away for anyone on a shared device who'd rather not.
  bool _rememberMe = true;

  // Only ever set in sign-up mode — carried through to AuthService.signUp,
  // which hands it off (see its pending-avatar mechanism) for main.dart to
  // seed onto the freshly-created account's AppState.
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_rememberedEmailKey);
    if (saved == null || !mounted) return;
    setState(() => _emailController.text = saved);
  }

  // Switching modes starts each one with a clean slate — otherwise
  // whatever was typed (or pre-filled by Remember Me) in Sign In carries
  // straight over into Sign Up, and vice versa, which reads as the app
  // reusing someone else's credentials rather than just an empty form.
  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _emailController.clear();
      _passwordController.clear();
      _avatarBase64 = null;
    });
    // Sign In still gets its own remembered email back, same as a fresh
    // launch of the screen would.
    if (!_isSignUp) _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null) return;
    final base64 = await pickAvatarAsBase64(source);
    if (base64 == null || !mounted) return;
    setState(() => _avatarBase64 = base64);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          avatarBase64: _avatarBase64,
        );
      } else {
        await _authService.signIn(email: _emailController.text, password: _passwordController.text);
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString(_rememberedEmailKey, _emailController.text.trim());
        } else {
          await prefs.remove(_rememberedEmailKey);
        }
      }
      // No further navigation needed here — main.dart's authStateChanges
      // listener picks up the new session and swaps this screen out (via
      // the welcome screen first, for a fresh sign-up).
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Dev convenience only — fills and submits the shared test account in
  // one tap instead of typing it in every time during testing. Remove
  // this button (and this method) before shipping to real users; it has
  // no business being in front of anyone but us during development.
  Future<void> _quickTestSignIn() async {
    _emailController.text = 'lumina.test@example.com';
    _passwordController.text = 'TestPass123';
    if (_isSignUp) setState(() => _isSignUp = false);
    await _submit();
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.authForgotPasswordNeedEmail);
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.authPasswordResetSent(email),
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forced to the light theme regardless of device/system dark mode —
    // not just the background (a plain color override there would've
    // left every scheme.onSurfaceVariant/outline-colored text using the
    // *dark* scheme's light-toned colors, unreadable against a light
    // background). AppTheme.light's own scaffoldBackgroundColor already
    // is the same warm cream the rest of the app uses, so nothing extra
    // is needed for that either. A Builder is required so the
    // Theme.of(context) calls below actually see this override — the
    // outer `context` this build() receives is still the old one.
    return Theme(
      data: AppTheme.light,
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          body: Stack(
        children: [
          // Soft mint/peach glow blobs in the corners — same decorative
          // background the web mockups use behind the sign-up card.
          Positioned(
            top: -120,
            left: -100,
            child: _GlowBlob(color: scheme.primaryContainer),
          ),
          Positioned(
            bottom: -140,
            right: -110,
            child: _GlowBlob(color: scheme.secondaryContainer),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // logo.png (icon + "Moodlet" + subtitle baked into
                      // one image), not logoIcon.png — no circle
                      // background behind it (unlike the old
                      // self_improvement placeholder), since the artwork
                      // already has its own distinct look.
                      Image.asset('assets/branding/logo.png', height: 84),
                      const SizedBox(height: 16),
                      // "Moodlet" dropped here in Sign In mode — the logo
                      // above already says it, so this was just a
                      // redundant second copy of the same word. Sign Up
                      // still shows "Create Account", which is real,
                      // distinct information.
                      if (_isSignUp)
                        Text(l10n.authCreateAccount,
                            textAlign: TextAlign.center,
                            style:
                                textTheme.headlineMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp ? l10n.authJoinSubtitle : l10n.authSignInSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      FloatingCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isSignUp) ...[
                                Center(
                                  child: GestureDetector(
                                    onTap: _submitting ? null : _pickAvatar,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 44,
                                          backgroundColor: scheme.primaryContainer,
                                          backgroundImage:
                                              _avatarBase64 != null ? MemoryImage(base64Decode(_avatarBase64!)) : null,
                                          child: _avatarBase64 == null
                                              ? Icon(Icons.person, size: 44, color: scheme.onPrimaryContainer)
                                              : null,
                                        ),
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: scheme.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: scheme.surfaceContainerLowest, width: 2),
                                            ),
                                            child: Icon(Icons.photo_camera, size: 16, color: scheme.onPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: _submitting ? null : _pickAvatar,
                                    child: Text(_avatarBase64 == null ? l10n.authAddPhoto : l10n.authChangePhoto),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                    labelText: l10n.authEmailLabel, prefixIcon: const Icon(Icons.mail_outline)),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return l10n.authEmailEmptyValidator;
                                  if (!value.contains('@') || !value.contains('.')) return l10n.authEmailInvalidValidator;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: l10n.authPasswordLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  helperText: _isSignUp ? l10n.authPasswordHelper : null,
                                ),
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) return l10n.authPasswordEmptyValidator;
                                  if (_isSignUp && value.length < 6) return l10n.authPasswordLengthValidator;
                                  return null;
                                },
                              ),
                              if (!_isSignUp)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: _submitting
                                          ? null
                                          : () => setState(() => _rememberMe = !_rememberMe),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            onChanged: _submitting
                                                ? null
                                                : (v) => setState(() => _rememberMe = v ?? true),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(l10n.authRememberMe,
                                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _submitting ? null : _forgotPassword,
                                      child: Text(l10n.authForgotPassword),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox(height: 8),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child:
                                      Text(_error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center),
                                ),
                              FilledButton(
                                onPressed: _submitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(_isSignUp ? l10n.authCreateAccount : l10n.authSignIn,
                                              style: const TextStyle(fontWeight: FontWeight.w700)),
                                          if (!_isSignUp) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isSignUp ? l10n.authAlreadyHaveAccount : l10n.authDontHaveAccount,
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                          TextButton(
                            onPressed: _submitting ? null : _toggleMode,
                            child: Text(_isSignUp ? l10n.authSignIn : l10n.authSignUp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dev-only shortcut — see _quickTestSignIn's doc comment.
                      TextButton.icon(
                        onPressed: _submitting ? null : _quickTestSignIn,
                        icon: Icon(Icons.science_outlined, size: 16, color: scheme.outline),
                        label: Text(l10n.authQuickTestSignIn, style: TextStyle(color: scheme.outline, fontSize: 12)),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.aboutVersion(_appVersion), style: TextStyle(fontSize: 12, color: scheme.outline)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        );
      }),
    );
  }
}

/// A soft, borderless radial glow — the corner decoration behind the auth
/// card. Uses a fading [RadialGradient] rather than an actual blur filter
/// (no [BackdropFilter]/[ImageFilter]) since a circle already shaped soft
/// at the edges gets the same effect far more cheaply.
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
