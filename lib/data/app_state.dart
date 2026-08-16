import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Single source of truth for the whole app: theme mode, Aura/notification
/// toggles, and every journal/check-in entry. Persists to [SharedPreferences]
/// as a local offline cache, and to Firestore (see [CloudSyncService]) as
/// the cross-device source of truth for the signed-in user identified by
/// [uid] — every instance belongs to exactly one account, so signing out
/// and into a different account means a brand-new [AppState] rather than
/// this one being reused, which keeps one person's journal from ever
/// leaking into another's on a shared device.
class AppState extends ChangeNotifier {
  AppState({required this.uid, required this.userName, required this.userEmail, this.profilePhotoBase64}) {
    _restoreFuture = _restore();
  }

  final String uid;
  final _cloudSync = CloudSyncService();

  /// Completes once the initial restore (cloud fetch, or local-cache
  /// fallback) has finished applying its results to this AppState's
  /// fields. Every _persist() call triggered from *outside* _restore
  /// itself — i.e. every normal setter — waits for this first. Without
  /// it, something that fires automatically during the very first frame
  /// after login (JournalScreen generating today's reflection prompt, for
  /// instance) could persist this AppState's still-default, pre-restore
  /// field values a moment before _restore's own cloud fetch resolves —
  /// overwriting whatever real data was about to come down with defaults,
  /// even though nothing was ever actually lost in the cloud itself, just
  /// raced and stomped a fraction of a second later. This is set in the
  /// constructor (not left implicit) specifically so _restore's *own*
  /// internal persist calls can bypass it — they call _persistNow()
  /// directly instead of _persist(), since awaiting this Future from
  /// inside the very call that completes it would deadlock.
  late final Future<void> _restoreFuture;

  /// Public view of [_restoreFuture] — main.dart shows a brief loading
  /// screen until this resolves, rather than showing the real app
  /// immediately with whatever defaults happened to be seeded, then
  /// having the name/photo/etc. visibly pop in a moment later once the
  /// cloud fetch actually finishes.
  Future<void> get ready => _restoreFuture;

  ThemeMode themeMode = ThemeMode.light;
  bool auraEnabled = true;
  bool notificationsEnabled = true;

  /// Settings' Language picker — an ISO language code ('en', 'zh'), or
  /// null to follow the device's own system language (main.dart falls
  /// back to English for any system locale this app doesn't actually
  /// have a translation for).
  String? languageCode;

  /// Display name shown around the app (Settings' profile card, the top
  /// bar, Insights' greeting) — purely cosmetic, never used to sign in.
  /// Starts out derived from the Firebase account (display name if one
  /// was set, otherwise the part of the email before the @) and from then
  /// on is a normal persisted field like any other here, editable anytime
  /// from Settings via [setUserName].
  String userName;
  final String userEmail;

  /// Hard ceiling on [userName]'s length — enforced *here*, not just by
  /// the edit dialog's own TextField.maxLength. A mobile keyboard's
  /// predictive-text/autocomplete can swap in a whole suggested word in
  /// one platform-level update, which is a known way to slip past a
  /// TextField's live maxLength formatter on some devices — enforcing it
  /// again where the value actually gets saved means the stored name
  /// can never exceed this regardless of what got past the UI.
  static const maxUserNameLength = 10;

  void setUserName(String name) {
    var trimmed = name.trim();
    if (trimmed.length > maxUserNameLength) trimmed = trimmed.substring(0, maxUserNameLength);
    debugPrint('AppState.setUserName($uid): called with "$name" (trimmed: "$trimmed", current: "$userName")');
    if (trimmed.isEmpty || trimmed == userName) {
      debugPrint('AppState.setUserName($uid): no-op (empty, or same as current)');
      return;
    }
    userName = trimmed;
    notifyListeners();
    _persist();
  }

  /// Base64-encoded profile photo shown on Settings' profile card — a
  /// normal (mutable, persisted) field like the rest of AppState, just
  /// seeded from whatever was picked on the sign-up screen (see
  /// AuthService's pending-profile handoff) rather than starting null like
  /// most fields do. [_restore] overwrites this with the saved value on
  /// every launch after the first, same as anything else here.
  String? profilePhotoBase64;

  void setProfilePhoto(String? base64) {
    debugPrint('AppState.setProfilePhoto($uid): called with ${base64 == null ? 'null (removing)' : 'a photo (${base64.length} chars)'}');
    profilePhotoBase64 = base64;
    notifyListeners();
    _persist();
  }

  /// Whether the one-time "tap to chat with Aura" hint bubble has already
  /// been shown. Persisted so it truly only ever shows once, not just once
  /// per app launch.
  bool hasSeenAuraHint = false;

  /// User-supplied Gemini API key, pasted into Settings — powers Insights'
  /// "Top Themes" chart. Stored locally only (same SharedPreferences blob
  /// as everything else); never hardcoded into the app itself, since this
  /// is a public repo and a key committed into source would sit in git
  /// history forever.
  String? geminiApiKey;

  void setGeminiApiKey(String? key) {
    final trimmed = key?.trim();
    geminiApiKey = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
    _persist();
  }

  /// The Aura chat transcript — persisted so leaving and reopening the
  /// chat (or reloading the app) picks back up where it left off instead
  /// of resetting to just the opening greeting every time.
  final List<AuraChatMessage> auraMessages = [
    const AuraChatMessage(
        text: "Hi there! I'm Aura, your mindful companion. How are you feeling today?", fromAura: true),
  ];

  // Keeps the persisted transcript (and the local-storage blob it's saved
  // into) from growing without bound over months of daily chatting —
  // trims the oldest messages once it's exceeded, keeping only the most
  // recent conversation.
  static const _maxAuraMessages = 200;

  void addAuraMessage(AuraChatMessage message) {
    auraMessages.add(message);
    if (auraMessages.length > _maxAuraMessages) {
      auraMessages.removeRange(0, auraMessages.length - _maxAuraMessages);
    }
    notifyListeners();
    _persist();
  }

  /// Journal's "Daily Reflection" prompt, cached for whichever single day
  /// [_dailyReflectionDate] names (yyyy-mm-dd) — generated once per day
  /// (AI-written if a Gemini key is available, otherwise picked from a
  /// small local pool — see JournalScreen's _DailyReflectionBar) and then
  /// reused for the rest of that day rather than regenerated on every
  /// rebuild. Persisted so it stays the same prompt across reopening the
  /// app the same day, not just within one session.
  String? dailyReflectionPrompt;
  String? _dailyReflectionDate;

  /// The cached prompt if it's still for *today* — null otherwise (either
  /// nothing's been generated yet, or the cached one is from a previous
  /// day and needs replacing).
  String? get todaysReflectionPrompt {
    final today = _dateKey(DateTime.now());
    return _dailyReflectionDate == today ? dailyReflectionPrompt : null;
  }

  void setTodaysReflectionPrompt(String prompt) {
    dailyReflectionPrompt = prompt;
    _dailyReflectionDate = _dateKey(DateTime.now());
    notifyListeners();
    _persist();
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

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

  /// Testing helper: adds one real entry for each of the 7 days *before*
  /// today (today itself is deliberately skipped — see the loop below) —
  /// a randomly-picked mood/text/activity sample per day, so Insights'
  /// Weekly Trend chart has a full week to plot without waiting for
  /// actual real usage or manually logging a week's worth of entries by
  /// hand. Skips any day already at the daily cap rather than erroring.
  /// Adds fresh (freshly randomized) entries every time it's tapped, same
  /// as any other manual entry — use "Clear Today's Entries" (or swipe
  /// individual ones) to undo.
  void seedPastWeekForTesting() {
    final now = DateTime.now();
    // Each sample carries an activity tag on purpose (not just mood/text)
    // — "What affects your mood" (Insights) and "Key Insight" (Weekly
    // Detail) both work by correlating mood with tags, so entries with no
    // tags at all give them nothing to find and always fall back to the
    // same generic "not enough data" text, which looked like the feature
    // was just broken/stuck rather than correctly reporting there was
    // nothing to correlate yet.
    const samples = [
      (Mood.great, 'Feeling Great', 'Everything just clicked today — great energy all around.', 'Exercise'),
      (Mood.good, 'Feeling Good', 'Solid, easy day. Nothing dramatic, just steady and pleasant.', 'Friends'),
      (Mood.okay, 'Feeling Okay', 'Fine, but a bit flat — just going through the motions.', 'Work'),
      (Mood.sad, 'Feeling Down', "Rough one. Couldn't shake the low mood most of the day.", 'Work'),
      (Mood.good, 'Feeling Content', 'Simple day, but genuinely content with how it went.', 'Family'),
      (Mood.great, 'Feeling On Top', 'Big win today — still riding the high from it.', 'Exercise'),
      (Mood.okay, 'Feeling Meh', 'Middle-of-the-road day, nothing worth complaining about.', 'Sleep'),
    ];
    final random = Random();
    var added = false;
    // Starts at 1, not 0 — today is deliberately left alone so this stays
    // a "past week" backfill rather than also planting a fake entry on
    // top of whatever's actually been logged today.
    for (var daysAgo = 1; daysAgo <= 7; daysAgo++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
      if (hasReachedDailyCap(day)) continue;
      final (mood, title, text, activity) = samples[random.nextInt(samples.length)];
      _entries.add(JournalEntry(
        id: 'test-week-${day.microsecondsSinceEpoch}-$daysAgo',
        dateTime: day.add(const Duration(hours: 12)),
        mood: mood,
        title: title,
        text: text,
        activities: [activity],
      ));
      added = true;
    }
    if (added) {
      notifyListeners();
      _persist();
    }
  }

  /// Testing helper: wipes every entry outright — live and already-deleted
  /// alike — for a genuinely clean slate, unlike [clearTodayEntriesForTesting]
  /// which only soft-deletes today's (still recoverable, and leaves
  /// everything else untouched). This is permanent; there's no undo.
  void clearAllEntriesForTesting() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
    _persist();
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

  void setLanguageCode(String? code) {
    languageCode = code;
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
    // Schedules/cancels the actual daily reminder to match — a no-op on
    // web (see NotificationService's doc for why), and safe to call even
    // if permission hasn't been granted yet (requestPermission is part of
    // scheduleDailyReminder's own flow).
    if (value) {
      NotificationService.scheduleDailyReminder();
    } else {
      NotificationService.cancelDailyReminder();
    }
  }

  /// Marks the Aura hint bubble as seen so it never shows again. Safe to
  /// call repeatedly — a no-op once already dismissed.
  void dismissAuraHint() {
    if (hasSeenAuraHint) return;
    hasSeenAuraHint = true;
    notifyListeners();
    _persist();
  }

  // Scoped per-account (not a single shared key) so switching to a
  // different Firebase account on the same device/browser never reads
  // back the previous account's cached journal before the real Firestore
  // data has a chance to load.
  String get _prefsKey => _prefsKeyFor(uid);

  static String _prefsKeyFor(String uid) => 'lumina_app_state_v1_$uid';

  /// Wipes this account's local cache — part of account deletion (see
  /// AuthService.deleteAccount). A plain static (not an instance method)
  /// since by the time it's useful to call, the AppState instance itself
  /// is already on its way out along with the rest of the signed-in app.
  static Future<void> clearLocalCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyFor(uid));
    } catch (_) {
      // Best-effort — see _persist's own local-write handling for why.
    }
  }

  Future<void> _restore() async {
    debugPrint('AppState._restore($uid): starting — fetching from Firestore...');
    // Firestore is the cross-device source of truth — try it first. Falls
    // back to the local cache below if offline or this account has never
    // synced before, so the app still opens with whatever it last saw.
    Map<String, dynamic>? map;
    var fromCloud = false;
    try {
      map = await _cloudSync.fetch(uid);
      fromCloud = map != null;
      debugPrint('AppState._restore($uid): cloud fetch returned '
          '${map == null ? 'null (nothing saved, or fetch failed — see CloudSyncService.fetch log above)' : 'data — userName=${map['userName']}, hasPhoto=${map['profilePhoto'] != null}'}');
    } catch (e) {
      debugPrint('AppState._restore($uid): cloud fetch threw: $e');
      map = null;
    }
    if (map == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_prefsKey);
        if (raw != null) map = jsonDecode(raw) as Map<String, dynamic>;
        debugPrint('AppState._restore($uid): falling back to local cache — '
            '${map == null ? 'nothing cached either (key: $_prefsKey)' : 'found cached data — userName=${map['userName']}, hasPhoto=${map['profilePhoto'] != null}'}');
      } catch (e) {
        // No usable local cache either — brand-new account, or a corrupt
        // one; keep the freshly-seeded defaults as-is.
        debugPrint('AppState._restore($uid): local cache read threw: $e');
      }
    }
    if (map == null) {
      // Found nothing anywhere — but this is NOT necessarily a brand-new
      // account: it's exactly as consistent with an *existing* account
      // whose cloud fetch just failed transiently (cold start, a network
      // blip) while also having no local cache (e.g. a fresh browser
      // profile). Those two cases are indistinguishable from here, so the
      // only safe move is to never persist blank defaults in this branch
      // — doing that unconditionally used to actively overwrite real
      // cloud data with nothing the moment a fetch merely hiccuped. The
      // one exception: a profile photo picked at sign-up (see AppState's
      // constructor param) is real, freshly-created data that doesn't
      // exist anywhere else yet, so that specific case still persists
      // eagerly rather than waiting on some later, unrelated change to
      // trigger the first save.
      if (profilePhotoBase64 != null) {
        debugPrint('AppState._restore($uid): nothing found, but a fresh sign-up photo is seeded — persisting it');
        // _persistNow directly, not _persist — _persist awaits
        // _restoreFuture first, which is this exact call's own Future;
        // awaiting it from inside itself would deadlock.
        await _persistNow();
      } else {
        debugPrint('AppState._restore($uid): nothing found anywhere — leaving cloud/local untouched '
            '(could be a genuinely new account, or just a failed fetch; not persisting blank defaults either way)');
      }
      return;
    }
    try {
      themeMode = (map['dark'] as bool? ?? false) ? ThemeMode.dark : ThemeMode.light;
      auraEnabled = map['aura'] as bool? ?? true;
      notificationsEnabled = map['notif'] as bool? ?? true;
      languageCode = map['lang'] as String?;
      hasSeenAuraHint = map['auraHintSeen'] as bool? ?? false;
      geminiApiKey = map['geminiApiKey'] as String?;
      userName = (map['userName'] as String?) ?? userName;
      profilePhotoBase64 = map['profilePhoto'] as String?;
      dailyReflectionPrompt = map['dailyReflectionPrompt'] as String?;
      _dailyReflectionDate = map['dailyReflectionDate'] as String?;
      final savedAuraMessages = map['auraMessages'] as List<dynamic>?;
      if (savedAuraMessages != null && savedAuraMessages.isNotEmpty) {
        auraMessages
          ..clear()
          ..addAll(savedAuraMessages.map((m) {
            final j = m as Map<String, dynamic>;
            return AuraChatMessage(text: j['text'] as String, fromAura: j['fromAura'] as bool);
          }));
      }
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
      debugPrint('AppState._restore($uid): applied — userName=$userName, hasPhoto=${profilePhotoBase64 != null}, '
          'fromCloud=$fromCloud — calling notifyListeners()');
      notifyListeners();
      // Re-persist if the restore itself changed anything (purge/trim), or
      // if this data came from the local cache rather than Firestore —
      // that means the cloud copy is missing or stale (offline last time,
      // or a brand-new local install), so push it up now to reconcile.
      // _persistNow directly (not _persist) — same deadlock reasoning as
      // the other internal call above.
      if (purgedExpired || trimmedOverCap || !fromCloud) _persistNow();
    } catch (e) {
      // Corrupt/missing prefs — keep whatever defaults were already set.
      debugPrint('AppState._restore($uid): applying restored data threw: $e');
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

  // Tracks the most recent _persist() call so [flush] (called right before
  // signing out — see AuthService/SettingsScreen) can wait for it. Without
  // this, signing out and back in quickly enough could start the new
  // session's cloud fetch before the previous edit's cloud push actually
  // landed — since _restore trusts any non-null cloud response over the
  // local cache, that stale-but-present read would win and the edit would
  // look like it never saved, even though it was on its way.
  Future<void>? _pendingPersist;

  /// Waits for the most recent save to fully finish (local cache *and*
  /// cloud). See [_pendingPersist]'s doc for why this matters specifically
  /// around signing out.
  Future<void> flush() => _pendingPersist ?? Future.value();

  Future<void> _persist() {
    // _pendingPersist is set synchronously, right here, to a Future
    // covering the *entire* operation (including the restore-wait below)
    // — so flush() called at any point after this, even before the
    // restore-wait resolves, still correctly waits for this save to
    // actually finish rather than returning early.
    final future = _persistAfterRestore();
    _pendingPersist = future;
    return future;
  }

  Future<void> _persistAfterRestore() async {
    // See _restoreFuture's doc — every *external* trigger for a save
    // (any setter) waits for the initial restore to actually finish
    // applying its data first, so nothing can persist stale pre-restore
    // defaults over real data that's on its way down from the cloud.
    await _restoreFuture;
    await _persistNow();
  }

  Future<void> _persistNow() async {
    final map = {
      'dark': themeMode == ThemeMode.dark,
      'aura': auraEnabled,
      'notif': notificationsEnabled,
      'lang': languageCode,
      'auraHintSeen': hasSeenAuraHint,
      'geminiApiKey': geminiApiKey,
      'profilePhoto': profilePhotoBase64,
      'userName': userName,
      'dailyReflectionPrompt': dailyReflectionPrompt,
      'dailyReflectionDate': _dailyReflectionDate,
      'auraMessages': auraMessages.map((m) => {'text': m.text, 'fromAura': m.fromAura}).toList(),
      'entries': _entries.map(_entryToJson).toList(),
    };
    debugPrint('AppState._persistNow($uid): saving — userName=$userName, hasPhoto=${profilePhotoBase64 != null}');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(map));
    } catch (_) {
      // Best-effort local cache only.
    }
    // Awaited now (not fire-and-forget) so flush() above actually means
    // something — CloudSyncService.push still swallows its own errors
    // (e.g. offline), so this still never throws back into whatever
    // action triggered the save.
    await _cloudSync.push(uid, map);
    debugPrint('AppState._persistNow($uid): cloud push finished (see CloudSyncService log above for success/failure)');
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

/// One message in the Aura chat transcript — see [AppState.auraMessages].
@immutable
class AuraChatMessage {
  const AuraChatMessage({required this.text, required this.fromAura});

  final String text;
  final bool fromAura;
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
