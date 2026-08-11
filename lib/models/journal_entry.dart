import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

/// A single mood check-in or journal entry.
///
/// Both the "Daily Check-in" (mood + activities only) and the full
/// "Journal Entry" (mood + free text) mockups produce the same record —
/// they only differ in which fields are filled in.
@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.dateTime,
    required this.mood,
    required this.title,
    this.text = '',
    this.tags = const [],
    this.activities = const [],
  });

  final String id;
  final DateTime dateTime;
  final Mood mood;

  /// e.g. "Feeling Peaceful" — the headline shown on entry cards.
  final String title;
  final String text;
  final List<String> tags;
  final List<String> activities;

  bool isSameDay(DateTime other) =>
      dateTime.year == other.year && dateTime.month == other.month && dateTime.day == other.day;
}
