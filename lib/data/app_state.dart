import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';

/// Single source of truth for the whole app: theme mode, Aura/notification
/// toggles, and every journal/check-in entry. Persists to [SharedPreferences]
/// so a reload doesn't lose what you typed.
class AppState extends ChangeNotifier {
  AppState() {
    _seedDemoData();
    _restore();
  }

  ThemeMode themeMode = ThemeMode.light;
  bool auraEnabled = true;
  bool notificationsEnabled = true;
  String userName = 'Alex';
  String userEmail = 'alex.journal@example.com';

  final List<JournalEntry> _entries = [];
  List<JournalEntry> get entries => List.unmodifiable(
        _entries..sort((a, b) => b.dateTime.compareTo(a.dateTime)),
      );

  List<JournalEntry> entriesOn(DateTime day) =>
      _entries.where((e) => e.isSameDay(day)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  void addEntry(JournalEntry entry) {
    _entries.add(entry);
    notifyListeners();
    _persist();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    _persist();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    _persist();
  }

  void setAuraEnabled(bool value) {
    auraEnabled = value;
    notifyListeners();
    _persist();
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
    _persist();
  }

  void _seedDemoData() {
    final now = DateTime.now();
    DateTime at(int daysAgo, int hour, int minute) => DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysAgo)).add(Duration(hours: hour, minutes: minute));

    _entries.addAll([
      JournalEntry(
        id: 'seed-0',
        dateTime: at(0, 9, 30),
        mood: Mood.good,
        title: 'Feeling Peaceful',
        text:
            'Took a long walk in the park today. The weather was perfect, and I finally finished reading that book.',
        activities: const ['Exercise'],
      ),
      JournalEntry(
        id: 'seed-1',
        dateTime: at(0, 14, 15),
        mood: Mood.great,
        title: 'Feeling Productive',
        text: 'Cleared my inbox and finished the project proposal ahead of schedule. Feeling very accomplished.',
        activities: const ['Work'],
      ),
      JournalEntry(
        id: 'seed-2',
        dateTime: at(1, 18, 0),
        mood: Mood.good,
        title: 'Feeling Calm',
        text: 'A quiet evening in with a cup of tea and some music.',
        activities: const ['Hobby'],
      ),
      JournalEntry(
        id: 'seed-3',
        dateTime: at(2, 20, 0),
        mood: Mood.okay,
        title: 'Feeling Okay',
        text: 'Long day, nothing bad happened, just tired.',
        activities: const ['Sleep'],
      ),
      JournalEntry(
        id: 'seed-4',
        dateTime: at(3, 8, 0),
        mood: Mood.great,
        title: 'Feeling Great',
        text: 'Morning run with a friend, best way to start the day.',
        activities: const ['Exercise', 'Friends'],
      ),
      JournalEntry(
        id: 'seed-5',
        dateTime: at(4, 19, 30),
        mood: Mood.sad,
        title: 'Feeling Sad',
        text: 'Missed an old friend today.',
        activities: const ['Family'],
      ),
      JournalEntry(
        id: 'seed-6',
        dateTime: at(5, 21, 0),
        mood: Mood.good,
        title: 'Feeling Cozy',
        text: 'Read a few chapters before bed.',
        activities: const ['Hobby'],
      ),
    ]);
  }

  static const _prefsKey = 'lumina_app_state_v1';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      themeMode = (map['dark'] as bool? ?? false) ? ThemeMode.dark : ThemeMode.light;
      auraEnabled = map['aura'] as bool? ?? true;
      notificationsEnabled = map['notif'] as bool? ?? true;
      final saved = (map['entries'] as List<dynamic>? ?? [])
          .map((e) => _entryFromJson(e as Map<String, dynamic>))
          .toList();
      _entries.addAll(saved);
      notifyListeners();
    } catch (_) {
      // Corrupt/missing prefs — keep demo data only.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'dark': themeMode == ThemeMode.dark,
        'aura': auraEnabled,
        'notif': notificationsEnabled,
        'entries': _entries.where((e) => !e.id.startsWith('seed-')).map(_entryToJson).toList(),
      };
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  Map<String, dynamic> _entryToJson(JournalEntry e) => {
        'id': e.id,
        'dateTime': e.dateTime.toIso8601String(),
        'mood': e.mood.name,
        'title': e.title,
        'text': e.text,
        'tags': e.tags,
        'activities': e.activities,
      };

  JournalEntry _entryFromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        mood: Mood.values.byName(j['mood'] as String),
        title: j['title'] as String,
        text: j['text'] as String? ?? '',
        tags: (j['tags'] as List<dynamic>? ?? []).cast<String>(),
        activities: (j['activities'] as List<dynamic>? ?? []).cast<String>(),
      );
}

/// Makes [AppState] reachable from anywhere below it in the tree.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
