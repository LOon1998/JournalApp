import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';
import '../widgets/mini_chip.dart';
import 'deleted_entries_screen.dart';
import 'entry_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7; // Sun=0
    final selectedEntries = appState.entriesOn(_selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.yMMMM().format(_visibleMonth),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DeletedEntriesScreen(day: _selectedDay)),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: scheme.primary),
                        const SizedBox(width: 2),
                        Text('History',
                            style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _RoundIconButton(icon: Icons.chevron_left, onTap: () => _shiftMonth(-1)),
                const SizedBox(width: 8),
                _RoundIconButton(icon: Icons.chevron_right, onTap: () => _shiftMonth(1)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        FloatingCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.outline)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firstWeekday + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekday) return const SizedBox.shrink();
                  final day = index - firstWeekday + 1;
                  final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                  final entries = appState.entriesOn(date);
                  final isSelected = DateUtils.isSameDay(date, _selectedDay);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  return _DayCell(
                    day: day,
                    entries: entries,
                    selected: isSelected,
                    today: isToday,
                    onTap: () => setState(() => _selectedDay = date),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(DateFormat.MMMMd().format(_selectedDay),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (selectedEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No entries on this day yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          for (final entry in selectedEntries) _EntryDetailCard(key: ValueKey(entry.id), entry: entry),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: scheme.onSurfaceVariant)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.entries,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final int day;
  final List<JournalEntry> entries;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? scheme.tertiaryContainer : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onTertiaryContainer : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            if (entries.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in entries.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: e.mood.swatch),
                      ),
                    ),
                ],
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _EntryDetailCard extends StatefulWidget {
  const _EntryDetailCard({super.key, required this.entry});
  final JournalEntry entry;

  @override
  State<_EntryDetailCard> createState() => _EntryDetailCardState();
}

class _EntryDetailCardState extends State<_EntryDetailCard> {
  static const _collapsedTagCount = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final scheme = Theme.of(context).colorScheme;

    // Collapsed shows tags only, never the written text — so anything with
    // text at all has something to reveal. Only worth offering the toggle
    // when there's actually more to show.
    final labels = entry.labels;
    final hasOverflow = entry.text.isNotEmpty || labels.length > _collapsedTagCount;
    final visibleTags = _expanded ? labels : labels.take(_collapsedTagCount).toList();
    final hiddenTagCount = labels.length - visibleTags.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete entry?'),
              content: Text('Remove "${entry.title}" from this day? You can restore it later from History.'),
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
          showAppSnackBar(context, 'Entry deleted');
        },
        child: Material(
          color: entry.mood.swatch.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: entry.mood.swatch.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: entry.mood.swatch,
                        child: Icon(entry.mood.icon, color: entry.mood.onSwatch),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.title,
                                style:
                                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: entry.mood.onSwatch)),
                            Text(DateFormat('h:mm a').format(entry.dateTime),
                                style: TextStyle(fontSize: 12, color: scheme.outline)),
                          ],
                        ),
                      ),
                      if (hasOverflow)
                        IconButton(
                          onPressed: () => setState(() => _expanded = !_expanded),
                          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                              size: 20, color: entry.mood.onSwatch),
                          tooltip: _expanded ? 'Show less' : 'Show more',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                    ],
                  ),
                  if (_expanded && entry.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(entry.text, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
                  ],
                  if (labels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in visibleTags) MiniChip(label: a),
                        if (!_expanded && hiddenTagCount > 0) const MiniChip(label: '...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
