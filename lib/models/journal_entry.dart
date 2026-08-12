import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

/// A single mood check-in or journal entry.
///
/// Both the "Daily Check-in" (mood + activities only) and the full
/// "Journal Entry" (mood + free text) mockups produce the same record —
/// they only differ in which fields are filled in.
@immutable
class JournalEntry {
  /// Per-entry cap on [photos]. Entries are persisted as base64 text
  /// inside one JSON blob (see [AppState]'s doc comment), so this exists
  /// to keep that blob — and every single-entry edit's re-serialization
  /// of it — from growing unbounded, not as an arbitrary UX restriction.
  static const maxPhotos = 6;

  const JournalEntry({
    required this.id,
    required this.dateTime,
    required this.mood,
    required this.title,
    this.text = '',
    this.tags = const [],
    this.activities = const [],
    this.deletedAt,
    this.photos = const [],
    this.voiceNote,
    this.themeName,
  });

  final String id;
  final DateTime dateTime;
  final Mood mood;

  /// e.g. "Feeling Peaceful" — the headline shown on entry cards.
  final String title;
  final String text;
  final List<String> tags;
  final List<String> activities;

  /// Non-null when this entry has been soft-deleted — it's hidden from the
  /// timeline/calendar/insights but kept around so it can be restored from
  /// the Deleted Entries history screen.
  final DateTime? deletedAt;

  /// Photos attached to this entry, each base64-encoded (already
  /// compressed by image_picker before being stored). Embedded directly
  /// rather than saved as device files so they work identically — and
  /// survive a page reload — on every platform this app runs on,
  /// including web, where there's no real filesystem to save to.
  final List<String> photos;

  /// A single base64-encoded (AAC/.m4a) voice note attached to this
  /// entry, if any. Same embed-as-data reasoning as [photos]; capped at
  /// 60 seconds when recorded to keep the encoded size reasonable.
  final String? voiceNote;

  /// Key into Journal's `_journalThemes` map (e.g. "Sunset"), if a
  /// Writing Theme was picked when this entry was composed. Carried
  /// through to the detail screen so its cards stay tinted the same
  /// color the entry was written in, instead of reverting to plain
  /// white/neutral once saved. Null for entries written before this
  /// existed, or the demo/seed data.
  final String? themeName;

  /// The chips shown on this entry wherever it's displayed — [tags] and
  /// [activities] merged (deduplicated), since which of the two field an
  /// entry's chips ended up in depends on how it was created (Journal's
  /// composer only ever writes [tags]; the demo/seed entries were written
  /// directly with [activities]). Display code should read this instead
  /// of either field individually.
  List<String> get labels => {...tags, ...activities}.toList();

  bool get isDeleted => deletedAt != null;

  bool isSameDay(DateTime other) =>
      dateTime.year == other.year && dateTime.month == other.month && dateTime.day == other.day;

  JournalEntry copyWith({
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    List<String>? photos,
    String? voiceNote,
    bool clearVoiceNote = false,
  }) =>
      JournalEntry(
        id: id,
        dateTime: dateTime,
        mood: mood,
        title: title,
        text: text,
        tags: tags,
        activities: activities,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
        photos: photos ?? this.photos,
        voiceNote: clearVoiceNote ? null : (voiceNote ?? this.voiceNote),
        themeName: themeName,
      );
}
