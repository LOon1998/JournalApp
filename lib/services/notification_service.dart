import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/generated/app_localizations.dart';
import '../l10n/generated/app_localizations_en.dart';
import '../l10n/generated/app_localizations_zh.dart';
import 'app_lock_service.dart';
import 'device_language.dart';

/// Wraps flutter_local_notifications for the one thing this app actually
/// needs: a daily reminder to journal, toggled by Settings' "Notifications"
/// switch (see AppState.setNotificationsEnabled).
///
/// Scheduled background notifications aren't something web browsers
/// support the way a real OS does — there's no equivalent of "wake up at
/// 8pm even if the tab's been closed for hours." Every method here is a
/// deliberate no-op on web rather than a half-working approximation;
/// Android/iOS are where this is actually meant to work.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // No BuildContext exists here — this fires from a background alarm long
  // after any screen that could have supplied one, and even the
  // *scheduling* call site (AppState.setNotificationsEnabled) is on the
  // data layer, not a widget. DeviceLanguage.current is the same
  // context-free source main.dart's own pre-sign-in locale already reads
  // from (see its doc comment), so this follows whichever language was
  // actually picked on this device instead of defaulting to English.
  static AppLocalizations get _l10n =>
      DeviceLanguage.current == 'zh' ? AppLocalizationsZh() : AppLocalizationsEn();

  static const _dailyReminderId = 1;
  // 8 PM — a reasonable default "look back on your day" time, matching
  // when Journal's own Daily Reflection prompt is meant to be answered.
  // Not user-configurable yet; a natural follow-up if this turns out to
  // be the wrong time for people.
  static const _reminderHour = 20;
  static const _reminderMinute = 0;

  static Future<void> _ensureInitialized() async {
    if (kIsWeb || _initialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to whatever the timezone package already defaults to
      // (UTC) rather than crashing — the reminder still fires, just
      // potentially at the wrong local hour until this resolves itself
      // (e.g. next app update pulls in a fix, or the platform call
      // succeeds on a later attempt).
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  // Local-only (never synced via AppState/Firestore, same reasoning as
  // AppLockService's own pattern hash) marker for "this device has asked
  // the OS for notification permission at least once before" — the one
  // thing permission_handler's PermissionStatus can't tell us on its own.
  // Settings' own "Open Notification Settings" fallback link needs this to
  // tell a plain, still-pending "denied" (there's a real OS dialog left to
  // trigger — the switch itself should keep handling that) apart from a
  // "denied" that's actually stuck: some OEM Android skins misreport a
  // permanently-denied permission as plain "denied" rather than
  // permission_handler's own PermissionStatus.permanentlyDenied, so the
  // switch's own re-request silently does nothing and the OS never shows
  // its dialog again. Once we know for a fact a request has already been
  // made and still didn't land on granted, the fallback link is the only
  // thing left that's guaranteed to work, regardless of which flavor of
  // "not granted" permission_handler thinks this is.
  static const _requestedBeforeKey = 'notification_permission_requested_before';

  static Future<bool> hasRequestedPermissionBefore() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_requestedBeforeKey) ?? false;
  }

  /// Richer tri-state read of whether the OS will actually show this
  /// app's notifications — separate from AppState.notificationsEnabled,
  /// which is just this app's *own* in-app preference. Someone can block
  /// notifications for this app entirely from their phone's own system
  /// settings, outside the app altogether, without ever touching the
  /// in-app toggle. permission_handler's PermissionStatus (not
  /// flutter_local_notifications' own areNotificationsEnabled(), a plain
  /// bool) is what actually distinguishes "never asked yet" — there's
  /// still a real, working OS prompt to trigger — from "permanently
  /// denied" — only fixable via the OS's own settings now. Null on web,
  /// where notification permission isn't a concept the same way.
  static Future<PermissionStatus?> permissionStatus() async {
    if (kIsWeb) return null;
    return Permission.notification.status;
  }

  /// Asks the OS for permission to show notifications at all — required
  /// on Android 13+ and iOS before anything can actually display. Safe to
  /// call repeatedly: if already permanently denied, this just resolves
  /// straight back to that same status without showing anything — the
  /// OS's own rule (it only ever prompts once), not this app's. Callers
  /// that want to steer someone to system settings instead of silently
  /// hitting that wall should check [permissionStatus] first, the way
  /// Settings' own notification row does.
  static Future<PermissionStatus> requestPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    // The system's own notification-permission dialog can briefly steal
    // focus the same way switching away to another app does — see
    // ExternalActivityGuard's own doc for why this stops that from being
    // mistaken for actually leaving and re-locking the app (if Pattern
    // Lock is on) the moment it returns.
    ExternalActivityGuard.begin();
    final PermissionStatus status;
    try {
      status = await Permission.notification.request();
    } finally {
      ExternalActivityGuard.end();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requestedBeforeKey, true);
    return status;
  }

  /// Schedules (or reschedules, if one's already set) the daily reminder.
  /// Called both when the Settings switch turns on, and once at every app
  /// launch that already has it enabled — Android can drop scheduled
  /// alarms across a reboot or a force-stop, so re-applying it on launch
  /// is what keeps it from silently going stale.
  static Future<void> scheduleDailyReminder() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await requestPermission();
    final l10n = _l10n;
    await _plugin.zonedSchedule(
      _dailyReminderId,
      l10n.notificationTitle,
      l10n.notificationBody,
      _nextInstanceOfReminderTime(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          l10n.notificationChannelName,
          channelDescription: l10n.notificationChannelDescription,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Required by this version of the plugin's iOS scheduling API —
      // absoluteTime means "the time as computed" (already in the local
      // timezone via tz.local above), as opposed to interpreting it
      // relative to the device's wall-clock time some other way.
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // Repeats daily at the same time, rather than firing once.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(_dailyReminderId);
  }

  // Separate id from the real daily reminder — showing this one never
  // touches (or gets overwritten by) the actual scheduled notification.
  static const _testNotificationId = 2;

  /// Testing helper — fires the exact same notification the daily
  /// reminder shows, immediately, instead of waiting for 8pm. Lets
  /// someone confirm on a real device that permission is granted and
  /// notifications actually display, without sitting around all day.
  /// Throws on web (see class doc) — callers should only offer this
  /// button when `!kIsWeb`, same as the whole feature.
  static Future<void> showTestNotification() async {
    await _ensureInitialized();
    await requestPermission();
    final l10n = _l10n;
    await _plugin.show(
      _testNotificationId,
      l10n.notificationTitle,
      l10n.notificationBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          l10n.notificationChannelName,
          channelDescription: l10n.notificationChannelDescription,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static tz.TZDateTime _nextInstanceOfReminderTime() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, _reminderHour, _reminderMinute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
