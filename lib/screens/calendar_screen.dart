import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../theme/activity_icons.dart';
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
  const CalendarScreen({super.key, this.active = true});

  /// Whether this tab is the one currently showing — see JournalScreen's
  /// matching field for why this is needed (IndexedStack keeps every
  /// tab's State alive even while hidden).
  final bool active;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Same page size as Journal's own entries carousel and Deleted
  // Entries — a day can hold up to 10 live entries, which was a long
  // scroll shown all at once.
  static const _entriesPerPage = 5;

  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  int _currentPageIndex = 0;

  // Which entry card (if any) is expanded — lifted up here for the same
  // reason as Journal's own timeline: only one card open at a time, and
  // reset to collapsed after returning from viewing/editing any entry.
  String? _expandedEntryId;

  // Marks the selected-day heading ("August 16" + entry count) — used to
  // anchor the scroll position back there on every pagination tap, same
  // behavior as Journal's own entries pager (see JournalScreen._goToPage).
  final _selectedDayKey = GlobalKey();

  void _goToEntriesPage(int page) {
    setState(() {
      _currentPageIndex = page;
      _expandedEntryId = null;
    });
    void attempt() {
      if (!mounted) return;
      final targetContext = _selectedDayKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        Scrollable.ensureVisible(targetContext,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switched away to another bottom-nav tab — collapse whatever entry
    // card was expanded, same as Journal's own tab does.
    if (oldWidget.active && !widget.active && _expandedEntryId != null) {
      setState(() => _expandedEntryId = null);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7; // Sun=0
    final selectedEntries = appState.entriesOn(_selectedDay);
    // appState.entriesOn(date) is now itself a cached, O(1)-per-day-cell
    // lookup (see AppState's own doc on its entries caching) — this used
    // to keep its own separate per-build grouping specifically to avoid
    // that call's old full scan-and-sort over *every* entry ever written,
    // once for each of a month's ~35-42 day cells. Now that the
    // expensive part lives in AppState itself (built once, and only when
    // the entries actually change, not on every Calendar rebuild the way
    // this local version was), calling it directly per cell costs the
    // same as the map lookup this replaced.

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(_visibleMonth),
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
                  for (final d in [
                    l10n.calendarWeekdaySun,
                    l10n.calendarWeekdayMon,
                    l10n.calendarWeekdayTue,
                    l10n.calendarWeekdayWed,
                    l10n.calendarWeekdayThu,
                    l10n.calendarWeekdayFri,
                    l10n.calendarWeekdaySat,
                  ])
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
                    onTap: () => setState(() {
                      _selectedDay = date;
                      _currentPageIndex = 0;
                      _expandedEntryId = null;
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          key: _selectedDayKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(_selectedDay),
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
            child: Text(l10n.calendarNoEntriesYet, style: TextStyle(color: scheme.onSurfaceVariant)),
          )
        else
          Builder(
            builder: (context) {
              // Pages of up to _entriesPerPage entries — not the whole
              // day's list at once, which could run to 10 entries and a
              // very long scroll.
              final pageCount = (selectedEntries.length / _entriesPerPage).ceil();
              final page = _currentPageIndex.clamp(0, pageCount - 1);
              final pageStart = page * _entriesPerPage;
              final pageEnd = (pageStart + _entriesPerPage).clamp(0, selectedEntries.length);
              final pageEntries = selectedEntries.sublist(pageStart, pageEnd);
              return Column(
                children: [
                  for (final entry in pageEntries)
                    _EntryDetailCard(
                      key: ValueKey(entry.id),
                      entry: entry,
                      expanded: entry.id == _expandedEntryId,
                      onToggleExpand: () =>
                          setState(() => _expandedEntryId = _expandedEntryId == entry.id ? null : entry.id),
                      onOpened: () {
                        if (mounted) setState(() => _expandedEntryId = null);
                      },
                    ),
                  if (pageCount > 1) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: page > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            onPressed: page > 0 ? () => _goToEntriesPage(page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.deletedEntriesPrevPage,
                          ),
                        ),
                        for (var i = 0; i < pageCount; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == page ? scheme.primary : scheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        Visibility(
                          visible: page < pageCount - 1,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            onPressed: page < pageCount - 1 ? () => _goToEntriesPage(page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.deletedEntriesNextPage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
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
      color: scheme.surfaceContainerLowest,
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
          // Back to a filled circle, but a much lighter tint than the
          // original tertiaryContainer — light enough to no longer read
          // as the same grey as the "Awful" mood dot, while still being
          // an obvious soft highlight rather than a ring.
          color: selected ? scheme.tertiaryContainer.withValues(alpha: 0.35) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
                color: scheme.onSurface,
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

class _EntryDetailCard extends StatelessWidget {
  const _EntryDetailCard({
    super.key,
    required this.entry,
    required this.expanded,
    required this.onToggleExpand,
    required this.onOpened,
  });
  final JournalEntry entry;

  /// Whether this card is the one currently expanded — only one entry
  /// card is ever expanded at a time, tracked by the parent so expanding
  /// one collapses whichever was open before.
  final bool expanded;
  final VoidCallback onToggleExpand;

  /// Called after returning from viewing/editing this entry, so the
  /// parent can collapse whatever was expanded.
  final VoidCallback onOpened;

  static const _collapsedTagCount = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
    final visibleTags = expanded ? labels : labels.take(_collapsedTagCount).toList();
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
                title: Text(l10n.deletedHistoryFullTitle),
                content: Text(l10n.deletedHistoryFullBody(AppState.maxDeletedEntriesPerDay)),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionOk)),
                ],
              ),
            );
            return false;
          }
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.entryDeleteConfirmTitle),
              content: Text(l10n.entryDeleteConfirmBody(entryDisplayTitle(context, entry))),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionNo)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.actionYesDelete, style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) {
          AppStateScope.of(context).deleteEntry(entry.id);
          showAppSnackBar(context, l10n.entryDeletedSnackbar);
        },
        child: Material(
          // Same darker fill + visible border as Journal's own entry
          // card (see the comment there) — kept in sync since the two
          // lists are meant to read as the same kind of card.
          color: entry.mood.swatch.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
              );
              onOpened();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                // onSwatch, not swatch — see journal_screen.dart's entry
                // card border for why (swatch is a pale pastel, so even
                // full opacity never reads as a genuinely darker tone).
                border: Border.all(color: entry.mood.onSwatch.withValues(alpha: 0.55), width: 1.5),
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
                                Text(entryDisplayTitle(context, entry),
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: moodTextColor)),
                                if (hasCustomTitle) ...[
                                  const SizedBox(height: 2),
                                  Text(l10n.entryFeelingMood(moodLabel(context, entry.mood)),
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
                          Text(
                              DateFormat('h:mm a', Localizations.localeOf(context).toString())
                                  .format(entry.dateTime),
                              style: const TextStyle(fontSize: 12, color: Colors.black)),
                          if (hasOverflow)
                            IconButton(
                              onPressed: onToggleExpand,
                              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more,
                                  size: 20, color: moodTextColor),
                              tooltip: expanded ? l10n.entryShowLess : l10n.entryShowMore,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                      if (entry.text.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          // Capped to 100 words even when expanded, and
                          // maxLines matches Deleted Entries' own 3-line
                          // preview cap — see journal_screen's matching
                          // card for why unbounded text (by words or by
                          // lines) is a bad idea here.
                          expanded ? truncateWords(entry.text, 100) : entry.text,
                          maxLines: expanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: previewStyle.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final a in visibleTags) MiniChip(label: activityLabel(context, a)),
                            if (!expanded && hiddenTagCount > 0) const MiniChip(label: '...'),
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
