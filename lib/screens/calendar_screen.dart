import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_card.dart';

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
        Text(DateFormat.MMMMd().format(_selectedDay),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (selectedEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No entries on this day yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          for (final entry in selectedEntries) _EntryDetailCard(entry: entry),
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

class _EntryDetailCard extends StatelessWidget {
  const _EntryDetailCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: entry.mood.swatch.withValues(alpha: 0.15),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: entry.mood.onSwatch)),
                  Text(DateFormat('h:mm a').format(entry.dateTime),
                      style: TextStyle(fontSize: 12, color: scheme.outline)),
                ],
              ),
            ],
          ),
          if (entry.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(entry.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
          ],
          if (entry.activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final a in entry.activities) _MiniChip(label: a)],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
