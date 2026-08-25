import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_lock_service.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  // Single source of truth is AppState.maxUserNameLength now — it also
  // enforces this as a hard backstop when actually saving, since a
  // mobile keyboard's predictive text can slip past this field's own
  // live maxLength on some devices.
  static const _maxNameLength = AppState.maxUserNameLength;

  // Hides the whole "Testing Tools" card below (Clear Today's Entries /
  // Fill Past 7 Days / Clear All Entries / Send Test Notification) —
  // explicitly a hide, not a deletion, so it's a one-line flip back to
  // `true` rather than reconstructing the card from scratch once these
  // are needed again.
  static const _showTestingTools = false;

  _GeminiConnStatus _connStatus = _GeminiConnStatus.unknown;
  String? _connError;

  // null = not checked yet — treated as "not permanently blocked" until
  // proven otherwise, so the switch isn't shown blocked while this is
  // still resolving. Checked on open, and again every time this screen's
  // app resumes (see didChangeAppLifecycleState) — necessary now that
  // "Open Notification Settings" below can send someone out to the OS's
  // own settings and back without ever leaving this screen, which a
  // plain "check once on open" would miss entirely. permission_handler's
  // real PermissionStatus (not a plain bool) is what actually
  // distinguishes "never asked yet" — the switch should stay fully
  // tappable, since there's still a genuine OS prompt for it to trigger —
  // from "permanently denied", where only the row below (not the switch
  // itself) can still do anything about it.
  PermissionStatus? _notificationPermissionStatus;

  // See NotificationService.hasRequestedPermissionBefore's own doc — this
  // is what actually lets the check below tell a plain, still-pending
  // "denied" (there's a real OS dialog left for the switch to trigger)
  // apart from a "denied" that's stuck for good on some OEM Android skins
  // that don't report permanentlyDenied accurately.
  bool _hasRequestedNotificationPermissionBefore = false;

  bool get _notificationsPermanentlyBlocked =>
      _notificationPermissionStatus != null &&
      _notificationPermissionStatus != PermissionStatus.granted &&
      (_notificationPermissionStatus == PermissionStatus.permanentlyDenied ||
          _notificationPermissionStatus == PermissionStatus.restricted ||
          _hasRequestedNotificationPermissionBefore);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOsNotificationStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshOsNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshOsNotificationStatus() async {
    final status = await NotificationService.permissionStatus();
    final requestedBefore =
        await NotificationService.hasRequestedPermissionBefore();
    if (mounted) {
      setState(() {
        _notificationPermissionStatus = status;
        _hasRequestedNotificationPermissionBefore = requestedBefore;
      });
    }
  }

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
      // SafeArea — this is a full pushed screen with no bottom nav bar of
      // its own to absorb the gesture-bar inset the way HomeShell's tabs
      // do, so without it the last row (Delete Account) could end up
      // sitting under/behind the system bar on phones with a taller one,
      // same class of issue as Weekly Detail's Key Insight card had.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Column(
              children: [
                Text(
                  l10n.settingsTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsSubtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: appState.profilePhotoBytes != null
                            ? MemoryImage(appState.profilePhotoBytes!)
                            : null,
                        child: appState.profilePhotoBytes == null
                            ? Icon(
                                Icons.person,
                                size: 36,
                                color: scheme.onPrimaryContainer,
                              )
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
                              child: Text(
                                appState.userName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
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
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          appState.userEmail,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _editProfilePhoto(context, appState),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            l10n.settingsEditPhoto,
                            style: const TextStyle(fontSize: 13),
                          ),
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
                  Row(
                    children: [
                      Icon(Icons.palette, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.settingsAppearance,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                icon: Icons.light_mode,
                                label: l10n.settingsLight,
                                selected: appState.themeMode == ThemeMode.light,
                                onTap: () =>
                                    appState.setThemeMode(ThemeMode.light),
                              ),
                            ),
                            Expanded(
                              child: _ModeButton(
                                icon: Icons.dark_mode,
                                label: l10n.settingsDark,
                                selected: appState.themeMode == ThemeMode.dark,
                                onTap: () =>
                                    appState.setThemeMode(ThemeMode.dark),
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
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.settingsAiCompanion,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
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
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settingsGeneral,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    // Shown (and stays) off when the phone itself is
                    // blocking notifications for this app, regardless of
                    // AppState's own stored preference — that preference
                    // reflects what was last *asked for*, not what's
                    // actually happening, and leaving the switch on would
                    // be a lie: the daily reminder gets scheduled either
                    // way, but the OS silently drops it before it ever
                    // shows.
                    value:
                        appState.notificationsEnabled &&
                        !_notificationsPermanentlyBlocked,
                    // Never disabled, even while permanently blocked —
                    // requestPermission() (called from
                    // AppState.setNotificationsEnabled below) just
                    // silently no-ops in that case instead of re-prompting
                    // (the OS's own rule, not this app's, once it's been
                    // permanently denied), so there's no harm in leaving it
                    // tappable; the subtitle + Open Notification Settings
                    // button below are what actually guide through that
                    // case.
                    onChanged: (value) async {
                      // Awaited, not fire-and-forget — the OS permission
                      // dialog (if any) needs to actually finish being
                      // answered before the status refresh below reads
                      // anything meaningful.
                      await appState.setNotificationsEnabled(value);
                      await _refreshOsNotificationStatus();
                    },
                    secondary: const Icon(Icons.notifications),
                    title: Text(l10n.settingsNotifications),
                    subtitle: _notificationsPermanentlyBlocked
                        ? Text(
                            l10n.settingsNotificationsBlockedByOs,
                            style: TextStyle(color: scheme.error),
                          )
                        : null,
                  ),
                  // Only shown when permanently blocked — a dedicated,
                  // explicit action for that specific case, since the
                  // switch above still just re-requests (a no-op once
                  // permanently denied) rather than opening settings
                  // itself.
                  if (_notificationsPermanentlyBlocked)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          // Opening system settings backgrounds this app
                          // the same way switching away to another app
                          // does — see ExternalActivityGuard's own doc
                          // for why this stops that from being mistaken
                          // for actually leaving and re-locking the app
                          // (if Pattern Lock is on) the moment it returns.
                          ExternalActivityGuard.begin();
                          AppSettings.openAppSettings(
                            type: AppSettingsType.notification,
                          ).whenComplete(ExternalActivityGuard.end);
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(
                          l10n.settingsOpenSystemNotificationSettings,
                        ),
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.settingsLanguage),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _languageLabel(context, appState.languageCode),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
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
                      MaterialPageRoute(
                        builder: (_) => const PrivacySecurityScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: Text(l10n.settingsHelpSupport),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tour_outlined),
                    title: Text(l10n.settingsTakeTour),
                    trailing: const Icon(Icons.chevron_right),
                    // Pop-then-signal, not a direct call — the tour
                    // highlights widgets that live on HomeShell (bottom nav,
                    // Aura, the check-in card, ...), not this screen, so it
                    // can only actually run once we're back there and this
                    // route is gone. Popping first (rather than signaling
                    // then popping) keeps requestTourReplay's notifyListeners
                    // — and therefore HomeShell's rebuild — from firing while
                    // Settings is still the visible route on top of it.
                    onTap: () {
                      debugPrint(
                        '[Settings] "Take a Tour" tapped — popping, then requesting replay',
                      );
                      Navigator.of(context).maybePop();
                      appState.requestTourReplay();
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
            if (_showTestingTools) ...[
              const SizedBox(height: 20),
              FloatingCard(
                color: scheme.tertiaryContainer.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report_outlined, color: scheme.tertiary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settingsTestingTools,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: scheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.settingsTestingToolsSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _confirmClearToday(context, appState),
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: Text(l10n.settingsClearTodayButton),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            appState.seedPastWeekForTesting();
                            showAppSnackBar(
                              context,
                              l10n.settingsFillPastWeekSnackbar,
                            );
                          },
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.settingsFillPastWeek),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _confirmClearAll(context, appState),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(color: scheme.error),
                          ),
                          icon: const Icon(
                            Icons.delete_forever_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.settingsClearAllButton),
                        ),
                        // Web can't show real notifications at all (see
                        // NotificationService's doc) — hidden there rather
                        // than shown as a button that would just silently
                        // do nothing.
                        if (!kIsWeb)
                          OutlinedButton.icon(
                            onPressed: () async {
                              // showTestNotification() itself has no idea
                              // whether the Notifications switch above is on
                              // or off — it just fires straight through
                              // regardless, which read as a real bug once
                              // "off means off" was the whole point of that
                              // switch: turning it off and then having Test
                              // still show something looked exactly like the
                              // switch not actually doing anything. Gating
                              // it here, rather than inside
                              // showTestNotification itself, keeps that
                              // method free to still be called elsewhere as
                              // a raw permission check if that's ever
                              // needed again.
                              if (!appState.notificationsEnabled) {
                                showAppSnackBar(
                                  context,
                                  l10n.settingsTestNotificationDisabledSnackbar,
                                );
                                return;
                              }
                              await NotificationService.showTestNotification();
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                l10n.settingsTestNotificationSnackbar,
                              );
                            },
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.settingsTestNotification),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                    child: Text(
                      l10n.settingsLogOut,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                child: Text(
                  l10n.settingsDeleteAccount,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
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

  // A real, non-null stand-in for "System" inside this dialog only —
  // needed so showDialog's return value can actually tell "explicitly
  // chose System" apart from "backed out without choosing anything".
  // Both used to come back as the same plain `null`, which meant
  // tapping outside the dialog (or the back button) to just close it —
  // no different from cancelling any other picker — silently reset the
  // language to System instead of leaving whatever was already chosen
  // alone. Real bug, not just a rough edge: picking Chinese, reopening
  // this dialog later, and dismissing it *without* touching anything
  // would flip it straight back to English (or whatever the device's
  // own system language is).
  static const _systemOption = '__system__';

  Future<void> _pickLanguage(BuildContext context, AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          RadioGroup<String>(
            groupValue: appState.languageCode ?? _systemOption,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in const [_systemOption, 'en', 'zh'])
                  RadioListTile<String>(
                    value: option,
                    title: Text(
                      _languageLabel(
                        context,
                        option == _systemOption ? null : option,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    // Null here now unambiguously means "dismissed without choosing
    // anything" (tapped outside, hit back, ...) — nothing was actually
    // picked, so the language is left exactly as it already was, rather
    // than being reset to System.
    if (code == null) return;
    appState.setLanguageCode(code == _systemOption ? null : code);
  }

  /// Purely cosmetic — see AppState.userName's doc comment. Never touches
  /// sign-in, so there's no uniqueness check or backend call here at all,
  /// just a local rename.
  Future<void> _editName(BuildContext context, AppState appState) async {
    debugPrint(
      'SettingsScreen._editName: dialog opening, current name is "${appState.userName}"',
    );
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
          decoration: InputDecoration(
            hintText: l10n.settingsNameHint,
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    debugPrint(
      'SettingsScreen._editName: dialog closed, returned ${newName == null ? 'null (Cancel/dismissed)' : '"$newName"'}',
    );
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
  Future<void> _editProfilePhoto(
    BuildContext context,
    AppState appState,
  ) async {
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
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.settingsRemovePhoto,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
    final base64 = await pickAvatarAsBase64(
      action == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.actionClear,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.settingsClearAllConfirmButton,
              style: TextStyle(color: scheme.error),
            ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
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
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows whether Gemini is actually reachable — not just "a key exists",
/// but a real round-trip confirming it authenticates. Sits below Testing
/// Tools so it's easy to find right after configuring the key above.
///
/// Also the *only* place a personal API key can actually be entered — the
/// build this app is compiled into (Android, in particular) has no
/// build-time key baked in via --dart-define the way the web deploy does
/// (see gemini_service.dart's own doc), so without a working field here,
/// Aura/Insights/daily prompts have no key at all to call Gemini with and
/// just fail outright. resolveGeminiApiKey already prefers this saved key
/// over the build-time one, so pasting one in here always takes effect
/// immediately, on every platform.
class _GeminiConnectionCard extends StatefulWidget {
  const _GeminiConnectionCard({
    required this.connStatus,
    required this.connError,
    required this.onTest,
  });

  final _GeminiConnStatus connStatus;
  final String? connError;
  final void Function(String apiKey) onTest;

  @override
  State<_GeminiConnectionCard> createState() => _GeminiConnectionCardState();
}

class _GeminiConnectionCardState extends State<_GeminiConnectionCard> {
  late final _keyController = TextEditingController(
    text: AppStateScope.of(context).geminiApiKey ?? '',
  );
  bool _obscureKey = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _save(BuildContext context, AppState appState) {
    FocusScope.of(context).unfocus();
    appState.setGeminiApiKey(_keyController.text);
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.geminiApiKeySavedSnackbar,
    );
    // Immediate feedback on the key that was just typed, rather than
    // making someone hunt for the separate Test Connection button right
    // after already taking the "save" action.
    final saved = resolveGeminiApiKey(appState.geminiApiKey);
    if (saved != null) widget.onTest(saved);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final effectiveKey = resolveGeminiApiKey(appState.geminiApiKey);

    final (
      IconData icon,
      Color color,
      String label,
    ) = switch (widget.connStatus) {
      _ when effectiveKey == null => (
        Icons.key_off_outlined,
        scheme.onSurfaceVariant,
        l10n.geminiNoKeyConfigured,
      ),
      _GeminiConnStatus.testing => (
        Icons.sync,
        scheme.onSurfaceVariant,
        l10n.geminiTesting,
      ),
      _GeminiConnStatus.connected => (
        Icons.check_circle,
        Colors.green,
        l10n.geminiConnected,
      ),
      _GeminiConnStatus.failed => (
        Icons.error_outline,
        scheme.error,
        l10n.geminiConnectionFailed,
      ),
      _GeminiConnStatus.unknown => (
        Icons.help_outline,
        scheme.onSurfaceVariant,
        l10n.geminiNotTestedYet,
      ),
    };

    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.geminiConnectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: l10n.geminiApiKeyLabel,
              hintText: l10n.geminiApiKeyHint,
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            onSubmitted: (_) => _save(context, appState),
          ),
          // No "Get API Key" link here anymore — the app already ships
          // with a working key baked in at build time (see
          // resolveGeminiApiKey's own doc), so nobody actually needs to
          // go get their own just to use Aura/the other AI features. The
          // field itself stays, for anyone who wants to override that
          // with their own key regardless.
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => _save(context, appState),
              child: Text(l10n.geminiApiKeySaveButton),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          if (widget.connStatus == _GeminiConnStatus.failed &&
              widget.connError != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.connError!,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                effectiveKey == null ||
                    widget.connStatus == _GeminiConnStatus.testing
                ? null
                : () => widget.onTest(effectiveKey),
            icon: const Icon(Icons.wifi_tethering, size: 18),
            label: Text(l10n.geminiTestConnectionButton),
          ),
        ],
      ),
    );
  }
}
