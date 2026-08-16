import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';
import 'change_password_screen.dart';
import 'pattern_lock_setup_screen.dart';

/// Matches the "Privacy & Security" mockup: Change Password, Fingerprint
/// Unlock, and Pattern Lock, under an "Account Security" section.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  String? _uid;
  AppLockService? _lockService;

  bool _loading = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasPattern = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    final uid = AuthService().currentUser?.uid;
    _uid = uid;
    if (uid != null) {
      _lockService = AppLockService(uid);
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final service = _lockService!;
    final available = await service.isBiometricAvailable();
    final enabled = await service.isBiometricEnabled();
    final hasPattern = await service.hasPattern();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _hasPattern = hasPattern;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final service = _lockService;
    if (service == null) return;

    if (!value) {
      await service.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      return;
    }

    if (!_biometricAvailable) {
      showAppSnackBar(context, 'No fingerprint or face unlock is set up on this device');
      return;
    }

    // Require one real successful scan before turning it on — so a
    // half-broken sensor can't lock someone out without them knowing.
    setState(() => _biometricBusy = true);
    final ok = await service.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    if (ok) {
      await service.setBiometricEnabled(true);
      if (!mounted) return;
      setState(() => _biometricEnabled = true);
    } else {
      showAppSnackBar(context, "Couldn't verify — Fingerprint Unlock wasn't enabled");
    }
  }

  Future<void> _openPatternSetup() async {
    final uid = _uid;
    if (uid == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PatternLockSetupScreen(uid: uid)),
    );
    if (saved == true && mounted) {
      setState(() => _hasPattern = true);
    }
  }

  Future<void> _removePattern() async {
    final service = _lockService;
    if (service == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Pattern Lock?'),
        content: const Text("You'll no longer need a pattern to open Lumina."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.clearPattern();
    if (!mounted) return;
    setState(() => _hasPattern = false);
    showAppSnackBar(context, 'Pattern Lock removed');
  }

  void _handlePatternTap() {
    if (_hasPattern) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.pattern),
              title: const Text('Change Pattern'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openPatternSetup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pattern_outlined),
              title: const Text('Remove Pattern'),
              onTap: () {
                Navigator.of(ctx).pop();
                _removePattern();
              },
            ),
          ]),
        ),
      );
    } else {
      _openPatternSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep your journal for your eyes only — protect your account and lock the app on this device.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    FloatingCard(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: Row(children: [
                              Icon(Icons.security, color: scheme.primary),
                              const SizedBox(width: 8),
                              Text('Account Security',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                            ),
                          ),
                          SwitchListTile(
                            secondary: _biometricBusy
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))
                                : const Icon(Icons.fingerprint),
                            title: const Text('Fingerprint Unlock'),
                            subtitle: _biometricAvailable ? null : const Text('Not available on this device'),
                            value: _biometricEnabled,
                            onChanged: _biometricBusy ? null : _toggleBiometric,
                          ),
                          ListTile(
                            leading: const Icon(Icons.pattern),
                            title: const Text('Pattern Lock'),
                            subtitle: Text(_hasPattern ? 'On' : 'Not set'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _handlePatternTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
