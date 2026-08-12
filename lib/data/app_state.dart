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

  /// Id of the entry most recently created via [addQuickEntry] — used the
  /// same way as [pendingCheckIn]: HomeShell switches to the Journal tab
  /// while this is non-null, and JournalScreen consumes it (via
  /// [takeJustAddedEntryId]) to know which entry to scroll to and briefly
  /// highlight, so "Save Mood Only" shows you exactly where it landed
  /// instead of just silently filing it away.
  String? justAddedEntryId;

  /// "Save Mood Only" — creates a complete entry straight from a mood (+
  /// optional activities) pick, with no trip through Journal's composer,
  /// unlike [handOffCheckInToJournal] ("Save & Write Journal").
  void addQuickEntry(Mood mood, List<String> activities) {
    final entry = JournalEntry(
      id: 'quick-${DateTime.now().microsecondsSinceEpoch}',
      dateTime: DateTime.now(),
      mood: mood,
      title: 'Feeling ${mood.label}',
      activities: activities,
    );
    addEntry(entry);
    justAddedEntryId = entry.id;
  }

  String? takeJustAddedEntryId() {
    final id = justAddedEntryId;
    justAddedEntryId = null;
    return id;
  }

  /// Per-day cap on how many entries can be logged — every entry-creating
  /// action (Journal's "Complete Entry", Today's two Save buttons,
  /// Insights' quick check-in) checks this via [hasReachedDailyCap]
  /// before creating anything. Deleting an entry frees up a slot again —
  /// this only ever counts *live* entries (see [entriesOn]), not
  /// soft-deleted ones sitting in history.
  static const maxDailyEntries = 10;

  bool hasReachedDailyCap(DateTime day) => entriesOn(day).length >= maxDailyEntries;

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

  /// Per-day cap on how many deleted entries can pile up in History —
  /// checked before a live entry is swiped/deleted (it lands in the same
  /// day's deleted bucket, keyed by its *original* date). Once a day's
  /// hit this, restoring or permanently deleting something from that
  /// day's History is what frees up room for another delete.
  static const maxDeletedEntriesPerDay = 20;

  bool hasReachedDeletedCap(DateTime day) => deletedEntriesOn(day).length >= maxDeletedEntriesPerDay;

  List<JournalEntry> entriesOn(DateTime day) =>
      _entries.where((e) => !e.isDeleted && e.isSameDay(day)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  void addEntry(JournalEntry entry) {
    _entries.add(entry);
    notifyListeners();
    _persist();
  }

  /// Edits an existing (non-deleted or deleted) entry in place. Only the
  /// fields passed are changed. Changing [mood] alone leaves [title]
  /// untouched — titles are user-owned (typed at creation, or edited
  /// directly on the detail screen) and shouldn't be silently overwritten
  /// just because the mood pill was tapped.
  void updateEntry(String id,
      {Mood? mood,
      String? text,
      String? title,
      List<String>? tags,
      String? themeName,
      bool clearThemeName = false}) {
    _replaceEntry(
      id,
      (e) => JournalEntry(
        id: e.id,
        dateTime: e.dateTime,
        mood: mood ?? e.mood,
        title: title ?? e.title,
        text: text ?? e.text,
        tags: tags ?? e.tags,
        activities: e.activities,
        deletedAt: e.deletedAt,
        photos: e.photos,
        voiceNote: e.voiceNote,
        themeName: clearThemeName ? null : (themeName ?? e.themeName),
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

  /// Wholesale-replaces an entry's photo list — used by the detail
  /// screen's Cancel button to restore whatever [addPhoto]/[removePhoto]
  /// calls happened during an edit session that's being discarded, since
  /// (unlike the body text) those commit to the entry immediately rather
  /// than staying a local draft.
  void setPhotos(String id, List<String> photos) {
    _replaceEntry(id, (e) => e.copyWith(photos: photos));
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
        themeName: e.themeName,
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
        themeName: e.themeName,
      ),
    );
  }

  /// Wholesale-replaces an entry's tags and activities together — same
  /// Cancel-button-restore purpose as [setPhotos], since [addLabel] and
  /// [removeLabel] also commit immediately rather than staying a local
  /// draft. Takes both fields at once (rather than just `tags`) because
  /// removeLabel can touch either one.
  void setLabels(String id, List<String> tags, List<String> activities) {
    _replaceEntry(
      id,
      (e) => JournalEntry(
        id: e.id,
        dateTime: e.dateTime,
        mood: e.mood,
        title: e.title,
        text: e.text,
        tags: tags,
        activities: activities,
        deletedAt: e.deletedAt,
        photos: e.photos,
        voiceNote: e.voiceNote,
        themeName: e.themeName,
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
      // seed-0/seed-1 deliberately land on *yesterday*, not today — at
      // fixed clock times (9:30 AM, 2:15 PM), sitting on "today" meant a
      // freshly created entry timestamped "now" would sort chronologically
      // *before* them (and so render above them) whenever tested before
      // 9:30 AM, which just looked like broken ordering. Keeping demo
      // content off today entirely means Today's Entries always starts
      // empty and fills purely with whatever's actually created, in true
      // creation order, with no fixed-time demo data mixed in.
      JournalEntry(
        id: 'seed-0',
        dateTime: at(1, 9, 30),
        mood: Mood.good,
        title: 'Feeling Peaceful',
        text:
            'Took a long walk in the park today. The weather was perfect, and I finally finished reading that book.',
        activities: const ['Exercise'],
      ),
      JournalEntry(
        id: 'seed-1',
        dateTime: at(1, 14, 15),
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
      // Purged on every launch, not just when History is opened — the
      // per-day deleted cap alone only bounds a single day's bucket, not
      // how much accumulates across every day the app's ever been used.
      final purgedExpired = _purgeExpiredDeletedEntries();
      // hasReachedDeletedCap only ever blocks a day's bucket from
      // *growing* past 20 going forward — it can't retroactively trim
      // entries that piled up past that before the cap existed (or from
      // restored backups/imports). This brings any such day back down to
      // 20 by dropping its oldest deletions first, same "most recent
      // wins" tiebreak deletedEntriesOn already sorts by.
      final trimmedOverCap = _trimDeletedEntriesOverCap();
      notifyListeners();
      if (purgedExpired || trimmedOverCap) _persist();
    } catch (_) {
      // Corrupt/missing prefs — keep demo data only.
    }
  }

  /// Permanently removes deleted entries that have sat in History longer
  /// than [deletedEntryExpiry] — the same "empties itself after a while"
  /// convention as Gmail/Photos' own Trash, so total storage stays
  /// bounded no matter how long the app's been used, rather than only
  /// ever growing as more gets deleted over months/years. Returns
  /// whether anything was actually removed.
  static const deletedEntryExpiry = Duration(days: 7);

  bool _purgeExpiredDeletedEntries() {
    final cutoff = DateTime.now().subtract(deletedEntryExpiry);
    final before = _entries.length;
    _entries.removeWhere((e) => e.isDeleted && e.deletedAt!.isBefore(cutoff));
    return _entries.length != before;
  }

  /// Brings any day's deleted bucket that's already over
  /// [maxDeletedEntriesPerDay] back down to it, permanently dropping
  /// that day's *oldest* deletions first. Returns whether anything was
  /// actually removed.
  bool _trimDeletedEntriesOverCap() {
    final deleted = _entries.where((e) => e.isDeleted).toList();
    // If the total is already within the cap, every individual day's
    // bucket necessarily is too — cheap skip for the common case.
    if (deleted.length <= maxDeletedEntriesPerDay) return false;

    final byDay = <String, List<JournalEntry>>{};
    for (final e in deleted) {
      final key = '${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}';
      byDay.putIfAbsent(key, () => []).add(e);
    }

    final idsToRemove = <String>{};
    for (final dayEntries in byDay.values) {
      if (dayEntries.length <= maxDeletedEntriesPerDay) continue;
      dayEntries.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!)); // most recently deleted first
      idsToRemove.addAll(dayEntries.skip(maxDeletedEntriesPerDay).map((e) => e.id));
    }
    if (idsToRemove.isEmpty) return false;
    _entries.removeWhere((e) => idsToRemove.contains(e.id));
    return true;
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
        'themeName': e.themeName,
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
        themeName: j['themeName'] as String?,
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
