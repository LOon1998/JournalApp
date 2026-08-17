import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:image_picker/image_picker.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/media_capture.dart';
import '../services/notification_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';

enum _GeminiConnStatus { unknown, testing, connected, failed }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Single source of truth is AppState.maxUserNameLength now — it also
  // enforces this as a hard backstop when actually saving, since a
  // mobile keyboard's predictive text can slip past this field's own
  // live maxLength on some devices.
  static const _maxNameLength = AppState.maxUserNameLength;

  _GeminiConnStatus _connStatus = _GeminiConnStatus.unknown;
  String? _connError;

  Future<void> _testGeminiConnection(String apiKey) async {
    setState(() {
      _connStatus = _GeminiConnStatus.testing;
      _connError = null;
    });
    try {
      await testGeminiConnection(apiKey);
      if (!mounted) return;
      setState(() => _connStatus = _GeminiConnStatus.connected);
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _connStatus = _GeminiConnStatus.failed;
        _connError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        // No back arrow and no "Lumina" branding here — this screen
        // already has its own "Settings" heading right below, and the
        // close button below is the one way to dismiss.
        automaticallyImplyLeading: false,
        // AppBar's own `actions` has its own built-in end padding, which
        // doesn't line up with where the settings gear icon actually
        // sits on LuminaTopBar. Rebuilding the same
        // Padding(horizontal: 24) + Row wrapper LuminaTopBar itself uses
        // puts this X in that exact same spot instead.
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: scheme.primary),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: l10n.actionClose,
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Column(
            children: [
              Text(l10n.settingsTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l10n.settingsSubtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 24),
          FloatingCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _editProfilePhoto(context, appState),
                  // Same green ring treatment as the top bar/Welcome
                  // back card's own avatar.
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primary, width: 2)),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: scheme.primaryContainer,
                      backgroundImage: appState.profilePhotoBase64 != null
                          ? MemoryImage(base64Decode(appState.profilePhotoBase64!))
                          : null,
                      child: appState.profilePhotoBase64 == null
                          ? Icon(Icons.self_improvement, size: 36, color: scheme.onPrimaryContainer)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(appState.userName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 2),
                          // Padding around the icon widens the actual tap
                          // target well past the icon's own 16px — a bare
                          // icon-sized GestureDetector is easy to miss
                          // entirely, especially with a mouse pointer.
                          GestureDetector(
                            onTap: () => _editName(context, appState),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.edit_outlined, size: 16, color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      Text(appState.userEmail, style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _editProfilePhoto(context, appState),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
                        child: Text(l10n.settingsEditPhoto, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.palette, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.settingsAppearance, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              icon: Icons.light_mode,
                              label: l10n.settingsLight,
                              selected: appState.themeMode == ThemeMode.light,
                              onTap: () => appState.setThemeMode(ThemeMode.light),
                            ),
                          ),
                          Expanded(
                            child: _ModeButton(
                              icon: Icons.dark_mode,
                              label: l10n.settingsDark,
                              selected: appState.themeMode == ThemeMode.dark,
                              onTap: () => appState.setThemeMode(ThemeMode.dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.smart_toy, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.settingsAiCompanion, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: appState.auraEnabled,
                  onChanged: appState.setAuraEnabled,
                  title: Text(l10n.settingsEnableAura),
                  subtitle: Text(l10n.settingsEnableAuraSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(children: [
                    Icon(Icons.settings, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.settingsGeneral, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
                SwitchListTile(
                  value: appState.notificationsEnabled,
                  onChanged: appState.setNotificationsEnabled,
                  secondary: const Icon(Icons.notifications),
                  title: Text(l10n.settingsNotifications),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.settingsLanguage),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_languageLabel(context, appState.languageCode), style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _pickLanguage(context, appState),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text(l10n.settingsPrivacySecurity),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: Text(l10n.settingsHelpSupport),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.tour_outlined),
                  title: Text(l10n.settingsTakeTour),
                  trailing: const Icon(Icons.chevron_right),
                  // Signal-and-pop, not a direct call — the tour highlights
                  // widgets that live on HomeShell (bottom nav, Aura, the
                  // check-in card, ...), not this screen, so it can only
                  // actually run once we're back there. HomeShell's own
                  // build() picks this up via takeTourReplayRequested().
                  onTap: () {
                    appState.requestTourReplay();
                    Navigator.of(context).maybePop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(l10n.settingsAboutLumina),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            color: scheme.tertiaryContainer.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.bug_report_outlined, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Text(l10n.settingsTestingTools,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsTestingToolsSubtitle,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmClearToday(context, appState),
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: Text(l10n.settingsClearTodayButton),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        appState.seedPastWeekForTesting();
                        showAppSnackBar(context, l10n.settingsFillPastWeekSnackbar);
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(l10n.settingsFillPastWeek),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmClearAll(context, appState),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
                      icon: const Icon(Icons.delete_forever_outlined, size: 18),
                      label: Text(l10n.settingsClearAllButton),
                    ),
                    // Web can't show real notifications at all (see
                    // NotificationService's doc) — hidden there rather
                    // than shown as a button that would just silently
                    // do nothing.
                    if (!kIsWeb)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await NotificationService.showTestNotification();
                          if (!context.mounted) return;
                          showAppSnackBar(context, l10n.settingsTestNotificationSnackbar);
                        },
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: Text(l10n.settingsTestNotification),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _GeminiConnectionCard(
            connStatus: _connStatus,
            connError: _connError,
            onTest: _testGeminiConnection,
          ),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _confirmLogOut(context),
                  child: Text(l10n.settingsLogOut, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              ),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              child: Text(l10n.settingsDeleteAccount, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  /// null (the default) means "follow the device's own language" — shown
  /// as "System" rather than silently picking English, so it's clear
  /// that's an active choice too, not the absence of one.
  String _languageLabel(BuildContext context, String? code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return AppLocalizations.of(context)!.languageSystem;
    }
  }

  Future<void> _pickLanguage(BuildContext context, AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          RadioGroup<String?>(
            groupValue: appState.languageCode,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in const [null, 'en', 'zh'])
                  RadioListTile<String?>(value: option, title: Text(_languageLabel(context, option))),
              ],
            ),
          ),
        ],
      ),
    );
    // showDialog returns null both when nothing was picked (dialog
    // dismissed) and when "System" (a real, meaningful null) was picked —
    // there's no way to tell those apart from the return value alone, so
    // this always applies whatever came back rather than trying to
    // distinguish "cancelled" from "chose System".
    appState.setLanguageCode(code);
  }

  /// Purely cosmetic — see AppState.userName's doc comment. Never touches
  /// sign-in, so there's no uniqueness check or backend call here at all,
  /// just a local rename.
  Future<void> _editName(BuildContext context, AppState appState) async {
    debugPrint('SettingsScreen._editName: dialog opening, current name is "${appState.userName}"');
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: appState.userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsEditNameDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: _maxNameLength,
          // Explicit, not left to the platform default — Flutter's own
          // default enforcement is `truncateAfterCompositionEnds` on iOS
          // (and Flutter Web reports itself as iOS on an iPhone browser),
          // which lets typing go past the limit temporarily instead of
          // hard-stopping at it like every other platform already does.
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(hintText: l10n.settingsNameHint, counterText: ''),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    debugPrint('SettingsScreen._editName: dialog closed, returned ${newName == null ? 'null (Cancel/dismissed)' : '"$newName"'}');
    // The actual rename happens immediately (not delayed) — AppState.flush
    // (awaited right before signing out, so a quick log-out can't race
    // ahead of an edit's own save) can only wait for a save already in
    // flight; delaying the call to setUserName itself meant flush() had
    // nothing to wait for yet if Log Out was tapped inside that window,
    // so the edit could be lost entirely rather than merely delayed.
    if (newName != null) appState.setUserName(newName);
    // Only the controller's *disposal* still waits out the dialog's close
    // transition (AlertDialog's default fade/scale-out runs ~150ms, several
    // frames) — showDialog's Future resolves the instant Navigator.pop() is
    // called, well before that animation finishes, so the TextField above
    // can still be on-screen (still bound to controller) for a while after
    // this line runs. Disposing immediately was causing "A
    // TextEditingController was used after being disposed."
    await Future.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  /// Same Take Photo / Choose from Gallery choice [showPhotoSourceSheet]
  /// gives entry photos, plus a Remove option when there's already a
  /// photo set — that third case doesn't apply to entry photos, so it's
  /// a local sheet here rather than a change to that shared one.
  Future<void> _editProfilePhoto(BuildContext context, AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.settingsTakePhoto),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.settingsChooseFromGallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (appState.profilePhotoBase64 != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.settingsRemovePhoto, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    // Called immediately, no delay — see _editName's matching fix for why
    // (a delayed call here can't be waited for by AppState.flush() if Log
    // Out is tapped inside that window, so the edit could be lost rather
    // than just delayed). Unlike _editName there's no TextEditingController
    // whose disposal needs to wait out the bottom sheet's own close
    // transition, so nothing here needs any delay at all now.
    if (action == 'remove') {
      appState.setProfilePhoto(null);
      return;
    }
    final base64 = await pickAvatarAsBase64(action == 'camera' ? ImageSource.camera : ImageSource.gallery);
    if (base64 == null) return;
    appState.setProfilePhoto(base64);
  }

  void _confirmClearToday(BuildContext context, AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearTodayConfirmTitle),
        content: Text(l10n.settingsClearTodayConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionClear, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      appState.clearTodayEntriesForTesting();
      showAppSnackBar(context, l10n.settingsClearTodaySnackbar);
    }
  }

  void _confirmClearAll(BuildContext context, AppState appState) async {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearAllConfirmTitle),
        content: Text(l10n.settingsClearAllConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsClearAllConfirmButton, style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      appState.clearAllEntriesForTesting();
      showAppSnackBar(context, l10n.settingsClearAllSnackbar);
    }
  }

  void _confirmLogOut(BuildContext context) {
    final appState = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLogOutConfirmTitle),
        content: Text(l10n.settingsLogOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Waits for whatever was most recently saved (a photo/name
              // edit, a new entry, ...) to actually finish reaching the
              // cloud before signing out — otherwise, signing back in
              // quickly enough could read the account's data *before*
              // that save landed and look like it never happened. Nothing
              // else to do after signOut() — main.dart's authStateChanges
              // listener sees it and swaps back to AuthScreen on its own,
              // tearing down this account's AppState with it.
              await appState.flush();
              AuthService().signOut();
            },
            child: Text(l10n.settingsLogOut),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: selected ? scheme.primary : scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Shows whether Gemini is actually reachable — not just "a key exists",
/// but a real round-trip confirming it authenticates. Sits below Testing
/// Tools so it's easy to find right after configuring the key above.
class _GeminiConnectionCard extends StatelessWidget {
  const _GeminiConnectionCard({required this.connStatus, required this.connError, required this.onTest});

  final _GeminiConnStatus connStatus;
  final String? connError;
  final void Function(String apiKey) onTest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final effectiveKey = resolveGeminiApiKey(appState.geminiApiKey);

    final (IconData icon, Color color, String label) = switch (connStatus) {
      _ when effectiveKey == null => (Icons.key_off_outlined, scheme.onSurfaceVariant, l10n.geminiNoKeyConfigured),
      _GeminiConnStatus.testing => (Icons.sync, scheme.onSurfaceVariant, l10n.geminiTesting),
      _GeminiConnStatus.connected => (Icons.check_circle, Colors.green, l10n.geminiConnected),
      _GeminiConnStatus.failed => (Icons.error_outline, scheme.error, l10n.geminiConnectionFailed),
      _GeminiConnStatus.unknown => (Icons.help_outline, scheme.onSurfaceVariant, l10n.geminiNotTestedYet),
    };

    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text(l10n.geminiConnectionTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
            ],
          ),
          if (connStatus == _GeminiConnStatus.failed && connError != null) ...[
            const SizedBox(height: 6),
            Text(connError!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                effectiveKey == null || connStatus == _GeminiConnStatus.testing ? null : () => onTest(effectiveKey),
            icon: const Icon(Icons.wifi_tethering, size: 18),
            label: Text(l10n.geminiTestConnectionButton),
          ),
        ],
      ),
    );
  }
}
