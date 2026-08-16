import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_card.dart';
import 'insights_screen.dart';

/// Full-screen breakdown of the same week Insights' Weekly Trend card
/// summarizes — opened by tapping that card. Reuses the exact same
/// [TrendChart] and mood data (moodScore/scoreToMood/weekdayAbbrev, all
/// shared from insights_screen.dart) so the two never disagree — shown
/// bigger, with the same "breathing" live-pulse animation as the compact
/// card, plus a per-mood breakdown and a locally-computed insight about
/// which tag/activity this week's better days had in common.
class WeeklyDetailScreen extends StatefulWidget {
  const WeeklyDetailScreen({super.key, required this.entries});

  final List<JournalEntry> entries;

  @override
  State<WeeklyDetailScreen> createState() => _WeeklyDetailScreenState();
}

class _WeeklyDetailScreenState extends State<WeeklyDetailScreen> with SingleTickerProviderStateMixin {
  // Same slow, continuous pulse as Insights' compact Weekly Trend card —
  // this screen used to deliberately skip it (a fixed t=0 kept the last
  // dot from fighting the tap-a-dot tooltips), but it's kept in sync with
  // the compact card now instead.
  late final _breatheController =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final last7Days =
        List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    final values = last7Days.map((day) {
      final dayEntries = entries.where((e) => e.isSameDay(day)).toList();
      if (dayEntries.isEmpty) return null;
      return dayEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) / dayEntries.length;
    }).toList();

    final weekEntries = entries.where((e) => last7Days.any((d) => e.isSameDay(d))).toList();
    final moodCounts = <Mood, int>{for (final m in Mood.values) m: 0};
    for (final e in weekEntries) {
      moodCounts[e.mood] = moodCounts[e.mood]! + 1;
    }
    final insight = _computeInsight(weekEntries);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(color: scheme.primary),
        title: Text('Weekly Detail', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, color: scheme.primary),
            tooltip: 'Share',
            onPressed: () => _share(weekEntries, moodCounts, insight),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  decoration:
                      BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
                  child: values.every((v) => v == null)
                      ? Center(child: Text('No data yet', style: TextStyle(color: scheme.outlineVariant)))
                      : TrendChart(
                          values: values,
                          last7Days: last7Days,
                          scheme: scheme,
                          breathe: _breatheController,
                          enableTooltips: true,
                        ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final day in last7Days)
                        Text(weekdayAbbrev(day.weekday), style: TextStyle(fontSize: 11, color: scheme.outlineVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final mood in Mood.values)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: mood.swatch),
                          ),
                          const SizedBox(width: 5),
                          Text(mood.label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEEKLY DISTRIBUTION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.primary)),
                const SizedBox(height: 16),
                if (weekEntries.isEmpty)
                  Text('Log a mood this week to see a breakdown.', style: TextStyle(color: scheme.onSurfaceVariant))
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          for (final mood in Mood.values)
                            if (moodCounts[mood]! > 0)
                              Expanded(flex: moodCounts[mood]!, child: Container(color: mood.swatch)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final mood in Mood.values)
                        if (moodCounts[mood]! > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: mood.swatch),
                              ),
                              const SizedBox(width: 5),
                              Text('${mood.label} (${moodCounts[mood]})',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                  child: Icon(Icons.psychology_outlined, size: 18, color: scheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Key Insight',
                          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(insight, style: TextStyle(color: scheme.onPrimaryContainer, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Computed entirely locally — no API — by comparing the average mood
  /// score of entries that carry a given tag/activity against the rest of
  /// the week, and surfacing whichever one shows the clearest gap.
  /// Falls back to a plain summary when there isn't enough data to say
  /// anything more specific.
  String _computeInsight(List<JournalEntry> weekEntries) {
    if (weekEntries.isEmpty) return 'Log a few entries this week to start seeing patterns.';

    final overallAvg =
        weekEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) / weekEntries.length;

    final byLabel = <String, List<double>>{};
    for (final e in weekEntries) {
      for (final label in e.labels) {
        byLabel.putIfAbsent(label, () => []).add(moodScore[e.mood]!.toDouble());
      }
    }

    String? bestLabel;
    double bestDelta = 0;
    byLabel.forEach((label, scores) {
      if (scores.length < 2) return; // one-off tags aren't a real pattern
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      final delta = avg - overallAvg;
      if (delta > bestDelta) {
        bestDelta = delta;
        bestLabel = label;
      }
    });

    if (bestLabel != null && overallAvg > 0) {
      final percent = ((bestDelta / overallAvg) * 100).round();
      if (percent >= 5) {
        return "You feel $percent% more positive on days you log \"$bestLabel\" — worth leaning into.";
      }
    }

    if (overallAvg >= 4) return "A genuinely great week overall — whatever you're doing, keep it up.";
    if (overallAvg <= 2.5) return 'A heavier week than usual — might be worth some extra care.';
    return "Pretty steady week — log a few more tagged entries and I'll start spotting real patterns.";
  }

  void _share(List<JournalEntry> weekEntries, Map<Mood, int> moodCounts, String insight) {
    final counts = [
      for (final mood in Mood.values)
        if (moodCounts[mood]! > 0) '${mood.label}: ${moodCounts[mood]}',
    ].join(', ');
    Share.share('My weekly mood detail from Lumina 🧘\n\n$counts\n\n$insight', subject: 'Weekly Detail');
  }
}
