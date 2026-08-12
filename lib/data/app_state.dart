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

  /// Whether the one-time "tap to chat with Aura" hint bubble has already
  /// been shown. Persisted so it truly only ever shows once, not just once
  /// per app launch.
  bool hasSeenAuraHint = false;

  /// Set when the Today check-in's mood/activities are handed off to the
  /// Journal screen to be composed into an actual entry. Nothing is saved
  /// to [entries] at this point — Today's "Save" only stages this; the
  /// entry is only created once "Complete Entry" is pressed on Journal.
  /// Not persisted; this is a one-shot in-memory handoff, consumed (and
  /// cleared) by [takePendingCheckIn].
  PendingCheckIn? pendingCheckIn;

  void handOffCheckInToJournal(Mood mood, List<String> activities) {
    pendingCheckIn = PendingCheckIn(mood: mood, activities: activities);
    notifyListeners();
  }

  PendingCheckIn? takePendingCheckIn() {
    final pending = pendingCheckIn;
    pendingCheckIn = null;
    return pending;
  }

  final List<JournalEntry> _entries = [];

  /// Live (non-deleted) entries, newest first.
  List<JournalEntry> get entries => List.unmodifiable(
        _entries.where((e) => !e.isDeleted).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime)),
      );

  /// Soft-deleted entries, most recently deleted first — backs the
  /// "Deleted Entries" history screen.
  List<JournalEntry> get deletedEntries => List.unmodifiable(
        _entries.where((e) => e.isDeleted).toList()..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!)),
      );

  /// Soft-deleted entries whose *original* date (not deletion date) was
  /// [day] — History is scoped per day rather than showing everything
  /// ever deleted, so it matches whichever day you were looking at.
  List<JournalEntry> deletedEntriesOn(DateTime day) =>
      _entries.where((e) => e.isDeleted && e.isSameDay(day)).toList()
        ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

  List<JournalEntry> entriesOn(DateTime day) =>
      _entries.where((e) => !e.isDeleted && e.isSameDay(day)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  void addEntry(JournalEntry entry) {
    _entries.add(entry);
    notifyListeners();
    _persist();
  }

  /// Edits an existing (non-deleted or deleted) entry in place. Only the
  /// fields passed are changed; `title` is re-derived from [mood] when a
  /// new mood is given, matching how entries are titled on creation.
  void updateEntry(String id, {Mood? mood, String? text, List<String>? tags}) {
    _replaceEntry(
      id,
      (e) => JournalEntry(
        id: e.id,
        dateTime: e.dateTime,
        mood: mood ?? e.mood,
        title: mood != null ? 'Feeling ${mood.label}' : e.title,
        text: text ?? e.text,
        tags: tags ?? e.tags,
        activities: e.activities,
        deletedAt: e.deletedAt,
        photos: e.photos,
        voiceNote: e.voiceNote,
      ),
    );
  }

  /// Appends a base64-encoded photo to an entry.
  void addPhoto(String id, String photoBase64) {
    _replaceEntry(id, (e) => e.copyWith(photos: [...e.photos, photoBase64]));
  }

  /// Removes a photo by its position in [JournalEntry.photos].
  void removePhoto(String id, int index) {
    _replaceEntry(id, (e) {
      if (index < 0 || index >= e.photos.length) return e;
      final updated = [...e.photos]..removeAt(index);
      return e.copyWith(photos: updated);
    });
  }

  /// Sets (replacing any existing one — an entry only has room for one)
  /// the entry's base64-encoded voice note.
  void setVoiceNote(String id, String voiceNoteBase64) {
    _replaceEntry(id, (e) => e.copyWith(voiceNote: voiceNoteBase64));
  }

  void removeVoiceNote(String id) {
    _replaceEntry(id, (e) => e.copyWith(clearVoiceNote: true));
  }

  /// Adds a custom chip to an entry (always into `tags` — new chips have
  /// no reason to go into the legacy `activities` field). No-ops if the
  /// entry already has that label (from either field) or the label is
  /// blank.
  void addLabel(String id, String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    _replaceEntry(id, (e) {
      if (e.labels.contains(trimmed)) return e;
      return JournalEntry(
        id: e.id,
        dateTime: e.dateTime,
        mood: e.mood,
        title: e.title,
        text: e.text,
        tags: [...e.tags, trimmed],
        activities: e.activities,
        deletedAt: e.deletedAt,
        photos: e.photos,
        voiceNote: e.voiceNote,
      );
    });
  }

  /// Removes a single chip from an entry's [JournalEntry.labels], no
  /// matter which of the two underlying fields it actually lives in.
  /// `updateEntry(tags: ...)` alone isn't enough for this: it only ever
  /// rewrites `tags`, so removing a label that came from the seed data's
  /// `activities` field (labels merge both, see JournalEntry.labels)
  /// would just have it recomputed right back by the untouched
  /// `activities` list.
  void removeLabel(String id, String label) {
    _replaceEntry(
      id,
      (e) => JournalEntry(
        id: e.id,
        dateTime: e.dateTime,
        mood: e.mood,
        title: e.title,
        text: e.text,
        tags: e.tags.where((t) => t != label).toList(),
        activities: e.activities.where((a) => a != label).toList(),
        deletedAt: e.deletedAt,
        photos: e.photos,
        voiceNote: e.voiceNote,
      ),
    );
  }

  /// Soft-delete: hides the entry from the timeline/calendar/insights but
  /// keeps it around so it can be restored from history.
  void deleteEntry(String id) {
    _replaceEntry(id, (e) => e.copyWith(deletedAt: DateTime.now()));
  }

  void restoreEntry(String id) {
    _replaceEntry(id, (e) => e.copyWith(clearDeletedAt: true));
  }

  /// Testing helper: soft-deletes every entry logged today in one shot, so
  /// UI that only shows when today has no entries yet (the Insights quick
  /// check-in card) can be exercised without swiping through each entry
  /// individually. Deleted this way, not wiped — still recoverable from
  /// History like any other delete.
  void clearTodayEntriesForTesting() {
    final today = DateTime.now();
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (!e.isDeleted && e.isSameDay(today)) {
        _entries[i] = e.copyWith(deletedAt: DateTime.now());
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _persist();
    }
  }

  /// Removes a soft-deleted entry for good. No-op if it isn't deleted.
  void permanentlyDeleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id && e.isDeleted);
    notifyListeners();
    _persist();
  }

  /// Empties the entire "Deleted Entries" history in one go, across every
  /// day. Prefer [clearDeletedEntriesOn] for the (now day-scoped) history
  /// screen's "Clear All" — this is kept for completeness.
  void clearDeletedEntries() {
    _entries.removeWhere((e) => e.isDeleted);
    notifyListeners();
    _persist();
  }

  /// Empties just [day]'s deleted entries, leaving other days' history
  /// untouched.
  void clearDeletedEntriesOn(DateTime day) {
    _entries.removeWhere((e) => e.isDeleted && e.isSameDay(day));
    notifyListeners();
    _persist();
  }

  void _replaceEntry(String id, JournalEntry Function(JournalEntry) transform) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _entries[index] = transform(_entries[index]);
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

  /// Marks the Aura hint bubble as seen so it never shows again. Safe to
  /// call repeatedly — a no-op once already dismissed.
  void dismissAuraHint() {
    if (hasSeenAuraHint) return;
    hasSeenAuraHint = true;
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
      hasSeenAuraHint = map['auraHintSeen'] as bool? ?? false;
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
        'auraHintSeen': hasSeenAuraHint,
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
        'deletedAt': e.deletedAt?.toIso8601String(),
        'photos': e.photos,
        'voiceNote': e.voiceNote,
      };

  JournalEntry _entryFromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        mood: Mood.values.byName(j['mood'] as String),
        title: j['title'] as String,
        text: j['text'] as String? ?? '',
        tags: (j['tags'] as List<dynamic>? ?? []).cast<String>(),
        activities: (j['activities'] as List<dynamic>? ?? []).cast<String>(),
        deletedAt: j['deletedAt'] != null ? DateTime.parse(j['deletedAt'] as String) : null,
        photos: (j['photos'] as List<dynamic>? ?? []).cast<String>(),
        voiceNote: j['voiceNote'] as String?,
      );
}

/// A staged-but-not-yet-saved check-in, handed from Today to Journal. See
/// [AppState.pendingCheckIn].
@immutable
class PendingCheckIn {
  const PendingCheckIn({required this.mood, required this.activities});

  final Mood mood;
  final List<String> activities;
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
