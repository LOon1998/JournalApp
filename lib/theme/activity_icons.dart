import 'package:flutter/material.dart';

/// Shared icon vocabulary for activities/tags — keyed by lowercase concept
/// name. Used two ways: (1) directly, for known preset options like
/// Today's activity chips (Work, Exercise, ...), matched case-
/// insensitively against the label itself; (2) as the fixed set Gemini is
/// constrained to choose from in Insights' "What affects your mood" tiles
/// (see gemini_service.dart's fetchActivityIcons) — it can only ever pick
/// a key from this list, never invent an icon, since IconData can't be
/// constructed dynamically from an arbitrary name.
const activityIconVocabulary = <String, IconData>{
  'exercise': Icons.directions_run,
  'work': Icons.work_outline,
  'sleep': Icons.bedtime_outlined,
  'family': Icons.family_restroom,
  'friends': Icons.groups_outlined,
  'hobby': Icons.palette_outlined,
  'reading': Icons.menu_book_outlined,
  'music': Icons.music_note_outlined,
  'food': Icons.restaurant_outlined,
  'travel': Icons.flight_takeoff_outlined,
  'nature': Icons.park_outlined,
  'meditation': Icons.self_improvement_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'study': Icons.school_outlined,
  'health': Icons.favorite_outline,
  'cleaning': Icons.cleaning_services_outlined,
  'gaming': Icons.sports_esports_outlined,
  'pets': Icons.pets_outlined,
  'weather': Icons.wb_sunny_outlined,
  'social': Icons.chat_bubble_outline,
};

/// Case-insensitive direct lookup for known preset labels (e.g. Today's
/// fixed activity options) — null if this label isn't in the vocabulary
/// at all (a custom tag like "dadada" that matches nothing, and Gemini
/// either isn't connected or didn't recognize it either). Callers showing
/// a tag/activity to the person should fall back to
/// [fallbackActivityIcon] rather than leaving it null — a genuinely
/// custom, one-off tag should still read as "a tag", not as a UI element
/// that's silently missing a piece.
IconData? activityIconFor(String label) => activityIconVocabulary[label.toLowerCase()];

/// Last-resort icon for a tag/activity that matched nothing — neither the
/// fixed vocabulary above nor (where applicable) Gemini's pick from it.
/// Generic on purpose: it doesn't claim to represent the tag's actual
/// meaning, just marks that this is a tag, so nothing ever renders with a
/// conspicuously empty spot where an icon should be.
const fallbackActivityIcon = Icons.local_offer_outlined;
