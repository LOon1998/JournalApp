import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import 'deleted_entries_screen.dart';

const _journalThemes = <String, Color>{
  'Sunset': Color(0xFFFBD6B0),
  'Sage': Color(0xFFD6E4C0),
  'Sky': Color(0xFFBFDBFE),
};

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _textController = TextEditingController();
  Mood _mood = Mood.good;
  String? _themeName;
  final Set<String> _tags = {};
  final _tagController = TextEditingController();
  bool _showTagField = false;

  static const _tagOptions = ['Family', 'Work', 'Health'];

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _complete() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a little something first')),
      );
      return;
    }
    AppStateScope.of(context).addEntry(
      JournalEntry(
        id: 'journal-${DateTime.now().microsecondsSinceEpoch}',
        dateTime: DateTime.now(),
        mood: _mood,
        title: 'Feeling ${_mood.label}',
        text: text,
        tags: _tags.toList(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry saved to your journal \u{1F4D6}')),
    );
    setState(() {
      _textController.clear();
      _tags.clear();
      _themeName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final today = DateTime.now();
    final todaysEntries = appState.entriesOn(today);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Timeline", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${todaysEntries.length} ${todaysEntries.length == 1 ? "entry" : "entries"}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeletedEntriesScreen()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 14, color: scheme.primary),
                      const SizedBox(width: 2),
                      Text('History',
                          style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in todaysEntries) _TimelineRow(entry: entry),
        if (todaysEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing logged yet today.', style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
                child: Icon(Icons.sentiment_very_satisfied, color: scheme.secondary),
              ),
              const SizedBox(height: 8),
              Text('NEW ENTRY',
                  style: TextStyle(
                      color: scheme.secondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Daily Reflection',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('"What\'s one small thing that made you smile today?"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurface)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Writing Theme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final entry in _journalThemes.entries)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ThemeSwatch(
                  color: entry.value,
                  selected: _themeName == entry.key,
                  onTap: () => setState(() => _themeName = _themeName == entry.key ? null : entry.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _themeName == null
                ? scheme.surfaceContainerLowest
                : Color.alphaBlend(
                    _journalThemes[_themeName]!.withValues(alpha: 0.35), scheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              TextField(
                controller: _textController,
                minLines: 8,
                maxLines: 12,
                style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  hintText: 'Write your thoughts here...',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: PopupMenuButton<Mood>(
                  initialValue: _mood,
                  onSelected: (mood) => setState(() => _mood = mood),
                  itemBuilder: (context) => [
                    for (final mood in Mood.values)
                      PopupMenuItem(value: mood, child: Text('${mood.emoji}  ${mood.label}')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.surfaceContainerHighest),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Feeling:', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        Text(_mood.emoji, style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo picker not available in this preview')),
                ),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice notes not available in this preview')),
                ),
                icon: const Icon(Icons.mic),
                label: const Text('Voice Note'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Tags (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in _tagOptions)
              _TagChip(
                label: tag,
                selected: _tags.contains(tag),
                onTap: () => setState(() {
                  if (!_tags.remove(tag)) _tags.add(tag);
                }),
              ),
            for (final tag in _tags.where((t) => !_tagOptions.contains(t)))
              _TagChip(label: tag, selected: true, onTap: () => setState(() => _tags.remove(tag))),
            InkWell(
              onTap: () => setState(() => _showTagField = !_showTagField),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant, width: 2),
                ),
                child: Icon(Icons.add, size: 18, color: scheme.outlineVariant),
              ),
            ),
          ],
        ),
        if (_showTagField) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(hintText: 'Add a tag'),
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    setState(() {
                      _tags.add(value.trim());
                      _tagController.clear();
                      _showTagField = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            ),
            onPressed: _complete,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete entry?'),
              content: Text('Remove "${entry.title}" from your timeline? You can restore it later from History.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Yes, delete', style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) {
          AppStateScope.of(context).deleteEntry(entry.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.surfaceContainerHighest),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: entry.mood.swatch,
                child: Icon(entry.mood.icon, size: 18, color: entry.mood.onSwatch),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(DateFormat('h:mm a').format(entry.dateTime),
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    if (entry.text.isNotEmpty)
                      Text(
                        entry.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.primary : scheme.surfaceContainerHighest, width: selected ? 3 : 2),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
      ),
    );
  }
}
