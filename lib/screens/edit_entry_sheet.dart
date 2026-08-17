import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../theme/activity_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/mood_emoji.dart';

/// Opens a bottom sheet for editing an existing entry's mood, text and
/// tags. Used from both the Journal timeline and the Calendar day detail,
/// so past entries aren't stuck the moment they're saved.
Future<void> showEditEntrySheet(BuildContext context, JournalEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EditEntrySheet(entry: entry),
  );
}

class _EditEntrySheet extends StatefulWidget {
  const _EditEntrySheet({required this.entry});
  final JournalEntry entry;

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late Mood _mood = widget.entry.mood;
  late final _textController = TextEditingController(text: widget.entry.text);
  late final Set<String> _tags = {...widget.entry.tags};

  static const _tagOptions = ['Family', 'Work', 'Health', 'Exercise', 'Hobby', 'Sleep'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _save() {
    AppStateScope.of(context).updateEntry(
      widget.entry.id,
      mood: _mood,
      text: _textController.text.trim(),
      tags: _tags.toList(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(l10n.editEntryTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mood in Mood.values)
                      _MoodChip(
                        mood: mood,
                        selected: _mood == mood,
                        onTap: () => setState(() => _mood = mood),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(hintText: l10n.journalWriteHint),
                ),
                const SizedBox(height: 16),
                Text(l10n.editEntryTagsLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in {..._tagOptions, ..._tags})
                      InkWell(
                        onTap: () => setState(() {
                          if (!_tags.remove(tag)) _tags.add(tag);
                        }),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _tags.contains(tag) ? scheme.primaryContainer.withValues(alpha: 0.6) : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(activityLabel(context, tag),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _tags.contains(tag) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
                        onPressed: _save,
                        child: Text(l10n.editEntrySaveChanges),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.selected, required this.onTap});
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? mood.swatch : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? mood.onSwatch : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoodEmoji(mood: mood, size: 18),
            const SizedBox(width: 6),
            Text(moodLabel(context, mood),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? mood.onSwatch : Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
