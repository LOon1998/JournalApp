import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../services/text_measure.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/entries_history_row.dart';
import '../widgets/floating_card.dart';
import '../widgets/mini_chip.dart';
import '../widgets/photo_tile.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMMd().format(_selectedDay),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            EntriesHistoryRow(
              entryCount: selectedEntries.length,
              onHistoryTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DeletedEntriesScreen(day: _selectedDay)),
              ),
            ),
          ],
        ),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Same plain pastel swatch used everywhere else
                          // a mood shows up as a color (the emoji picker's
                          // circles, the avatar backgrounds, ...) — the
                          // higher-contrast onSwatch companion looked
                          // right in isolation but too harsh/saturated
                          // for a whole row of small dots.
                          color: e.mood.swatch,
                        ),
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

    // A "Feeling {mood}" subtitle is only worth showing when the title
    // isn't already that exact string (i.e. a custom title was given) —
    // otherwise it'd just repeat the title back verbatim underneath it.
    final hasCustomTitle = entry.title != 'Feeling ${entry.mood.label}';

    // Mood.onSwatch is a fixed dark color meant for text on top of the
    // *fully opaque* pastel Mood.swatch (like the avatar below) — this
    // card's background is that same swatch blended at only 15% alpha
    // over the page, which in dark mode stays close to the page's own
    // near-black surface. onSwatch text there read as dark-on-near-black
    // — nearly invisible. The bright pastel swatch color itself reads
    // fine against a dark card, so brightness picks whichever of the
    // pair actually contrasts with this specific (tinted, not opaque)
    // background.
    final moodTextColor = scheme.brightness == Brightness.dark ? entry.mood.swatch : entry.mood.onSwatch;

    final labels = entry.labels;
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
          final appState = AppStateScope.of(context);
          if (appState.hasReachedDeletedCap(entry.dateTime)) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Deleted history is full'),
                content: Text(
                    "This day's History already has ${AppState.maxDeletedEntriesPerDay} deleted entries. Restore or permanently delete some from History before deleting another."),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              ),
            );
            return false;
          }
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
              // Needs the card's actual available width to tell whether
              // entry.text would really wrap/truncate at one line — a
              // short one-liner never would, and the expand/collapse
              // chevron would just toggle between two identical-looking
              // states, so it's only worth showing when there's
              // something real for it to reveal.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const previewStyle = TextStyle(fontSize: 14, height: 1.5);
                  final textOverflows = entry.text.isNotEmpty &&
                      textOverflowsOneLine(entry.text, previewStyle, constraints.maxWidth);
                  final hasOverflow = textOverflows || labels.length > _collapsedTagCount;
                  return Column(
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
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: moodTextColor)),
                                if (hasCustomTitle) ...[
                                  const SizedBox(height: 2),
                                  Text('Feeling ${entry.mood.label}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: scheme.outline)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.photos.isNotEmpty) ...[
                            Icon(Icons.photo_camera_outlined, size: 14, color: scheme.outline),
                            const SizedBox(width: 4),
                          ],
                          if (entry.voiceNote != null) ...[
                            Icon(Icons.mic, size: 14, color: scheme.outline),
                            const SizedBox(width: 4),
                          ],
                          Text(DateFormat('h:mm a').format(entry.dateTime),
                              style: TextStyle(fontSize: 12, color: scheme.outline)),
                          if (hasOverflow)
                            IconButton(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                                  size: 20, color: moodTextColor),
                              tooltip: _expanded ? 'Show less' : 'Show more',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                      if (entry.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          entry.text,
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: previewStyle.copyWith(color: scheme.onSurfaceVariant),
                        ),
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
                      if (entry.photos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        PhotoStrip(photos: entry.photos),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
