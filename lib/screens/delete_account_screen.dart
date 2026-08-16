import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/floating_card.dart';

/// Reached from Settings' "Delete Account" link — a dedicated confirmation
/// screen (rather than just a dialog) for something this permanent,
/// requiring the account's password before anything happens. Matches the
/// Lumina web mockup: what's about to be lost spelled out plainly, and two
/// clearly-weighted buttons (safe default vs. destructive).
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Same reasoning as Settings' Log Out flush — without waiting for
      // whatever was most recently saved to actually land first, a
      // pending write could arrive *after* deleteAccount's Firestore
      // delete and silently resurrect the very data this is supposed to
      // permanently remove.
      await AppStateScope.of(context).flush();
      await _authService.deleteAccount(_passwordController.text);
      // No further navigation needed — deleting the account signs it out,
      // and main.dart's authStateChanges listener swaps back to AuthScreen
      // (tearing this screen down with everything else) on its own.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.errorContainer,
                  child: Icon(Icons.heart_broken_outlined, size: 32, color: scheme.error),
                ),
                const SizedBox(height: 16),
                Text('Delete Account',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, height: 1.5),
                    children: [
                      const TextSpan(
                          text: "We're sad to see you go. If you delete your account, your digital sanctuary "
                              "will be permanently removed. "),
                      TextSpan(
                        text: 'This action cannot be undone.',
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FloatingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("What you'll lose",
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _LossRow(
                        icon: Icons.menu_book_outlined,
                        color: scheme.primaryContainer,
                        onColor: scheme.onPrimaryContainer,
                        title: 'Journals',
                        subtitle: 'All written entries and reflections',
                      ),
                      const SizedBox(height: 12),
                      _LossRow(
                        icon: Icons.sentiment_satisfied_alt_outlined,
                        color: scheme.secondaryContainer,
                        onColor: scheme.onSecondaryContainer,
                        title: 'Mood History',
                        subtitle: 'Your tracked emotional journey',
                      ),
                      const SizedBox(height: 12),
                      _LossRow(
                        icon: Icons.auto_awesome_outlined,
                        color: scheme.tertiaryContainer,
                        onColor: scheme.onTertiaryContainer,
                        title: 'Personal Insights',
                        subtitle: 'AI-generated patterns and summaries',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Confirm your password to continue',
                      style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, size: 18),
                        const SizedBox(width: 8),
                        const Text('Keep My Account', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submitting ? null : _deleteAccount,
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  child: _submitting
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.error),
                        )
                      : const Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LossRow extends StatelessWidget {
  const _LossRow({
    required this.icon,
    required this.color,
    required this.onColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color onColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, size: 18, color: onColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
