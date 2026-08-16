import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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

  /// Asks the OS for permission to show notifications at all — required
  /// on Android 13+ and iOS before anything can actually display. Safe to
  /// call repeatedly: the OS itself only ever prompts the person once,
  /// silently no-op-ing on every call after that (whichever way they
  /// answered).
  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
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
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Lumina',
      'How was your day? Take a moment to reflect. 🌙',
      _nextInstanceOfReminderTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'A gentle daily nudge to check in with yourself.',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
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
    await _plugin.show(
      _testNotificationId,
      'Lumina',
      'How was your day? Take a moment to reflect. 🌙',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'A gentle daily nudge to check in with yourself.',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
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
