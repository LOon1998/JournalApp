import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/media_capture.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';

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

  // Only ever set in sign-up mode — carried through to AuthService.signUp,
  // which hands it off (see its pending-avatar mechanism) for main.dart to
  // seed onto the freshly-created account's AppState.
  String? _avatarBase64;

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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?" again.');
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      showAppSnackBar(
        context,
        "Password reset email sent to $email — check your spam/junk folder if it doesn't show up.",
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.self_improvement, size: 32, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 16),
                      Text(_isSignUp ? 'Create Account' : 'Lumina',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Join Lumina and start your journaling journey.'
                            : 'Sign in to continue your journey of mindfulness.',
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
                                    child: Text(_avatarBase64 == null ? 'Add Photo' : 'Change Photo'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration:
                                    const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Enter your email';
                                  if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  helperText: _isSignUp ? 'Must be at least 6 characters.' : null,
                                ),
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) return 'Enter your password';
                                  if (_isSignUp && value.length < 6) return 'At least 6 characters';
                                  return null;
                                },
                              ),
                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _submitting ? null : _forgotPassword,
                                    child: const Text('Forgot password?'),
                                  ),
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
                                          Text(_isSignUp ? 'Create Account' : 'Sign In',
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
                          Text(_isSignUp ? 'Already have an account?' : "Don't have an account?",
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() {
                                      _isSignUp = !_isSignUp;
                                      _error = null;
                                    }),
                            child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dev-only shortcut — see _quickTestSignIn's doc comment.
                      TextButton.icon(
                        onPressed: _submitting ? null : _quickTestSignIn,
                        icon: Icon(Icons.science_outlined, size: 16, color: scheme.outline),
                        label: Text('Quick Test Sign In', style: TextStyle(color: scheme.outline, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
