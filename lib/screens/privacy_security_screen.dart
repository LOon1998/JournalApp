import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';
import 'change_password_screen.dart';
import 'pattern_lock_setup_screen.dart';

/// Matches the "Privacy & Security" mockup: Change Password and Pattern
/// Lock, under an "Account Security" section. Fingerprint Unlock was
/// dropped — not worth the added complexity/permissions for what it
/// actually offered here.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  String? _uid;
  AppLockService? _lockService;

  bool _loading = true;
  bool _hasPattern = false;

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
    final hasPattern = await service.hasPattern();
    if (!mounted) return;
    setState(() {
      _hasPattern = hasPattern;
      _loading = false;
    });
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacySecurityRemoveDialogTitle),
        content: Text(l10n.privacySecurityRemoveDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.actionCancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.actionRemove)),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.clearPattern();
    if (!mounted) return;
    setState(() => _hasPattern = false);
    showAppSnackBar(context, l10n.privacySecurityPatternRemovedSnackbar);
  }

  void _handlePatternTap() {
    final l10n = AppLocalizations.of(context)!;
    if (_hasPattern) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.pattern),
              title: Text(l10n.privacySecurityChangePattern),
              onTap: () {
                Navigator.of(ctx).pop();
                _openPatternSetup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pattern_outlined),
              title: Text(l10n.privacySecurityRemovePattern),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacySecurity)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.privacySecurityIntro,
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
                              Text(l10n.privacySecurityAccountSecurity,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: Text(l10n.changePasswordTitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.pattern),
                            title: Text(l10n.privacySecurityPatternLockRow),
                            subtitle: Text(_hasPattern ? l10n.privacySecurityOn : l10n.privacySecurityNotSet),
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
