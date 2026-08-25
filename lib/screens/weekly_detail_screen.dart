import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/app_lock_service.dart';
import '../theme/activity_icons.dart';
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

class _WeeklyDetailScreenState extends State<WeeklyDetailScreen>
    with TickerProviderStateMixin {
  // Same slow, continuous pulse as Insights' compact Weekly Trend card —
  // this screen used to deliberately skip it (a fixed t=0 kept the last
  // dot from fighting the tap-a-dot tooltips), but it's kept in sync with
  // the compact card now instead.
  late final _breatheController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  // Drives the Mood Percentage rings/numbers counting up from 0 to their
  // real value once, when this screen first opens — a one-shot 0->1
  // progress, separate from _breatheController's own continuous repeat.
  late final _countUpController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _breatheController.dispose();
    _countUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );

    final values = last7Days.map((day) {
      final dayEntries = entries.where((e) => e.isSameDay(day)).toList();
      if (dayEntries.isEmpty) return null;
      return dayEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) /
          dayEntries.length;
    }).toList();

    final weekEntries = entries
        .where((e) => last7Days.any((d) => e.isSameDay(d)))
        .toList();
    final moodCounts = <Mood, int>{for (final m in Mood.values) m: 0};
    for (final e in weekEntries) {
      moodCounts[e.mood] = moodCounts[e.mood]! + 1;
    }
    final tagInsights = _computeTagInsights(weekEntries);
    final insight = _insightSentence(context, weekEntries, tagInsights);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(color: scheme.primary),
        title: Text(
          l10n.weeklyDetailTitle,
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, color: scheme.primary),
            tooltip: l10n.actionShare,
            onPressed: () => _share(context, weekEntries, moodCounts, insight),
          ),
        ],
      ),
      // SafeArea, not just the ListView's own fixed bottom padding — a
      // flat 32 wasn't enough to clear the gesture bar on some phones
      // (reported on a Samsung Galaxy), since it doesn't know how tall
      // that bar actually is on a given device. SafeArea adds whatever
      // that real inset is on top of the 32, so the last card always
      // clears it regardless of phone model.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weeklyMoodOverview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: values.every((v) => v == null)
                        ? Center(
                            child: Text(
                              l10n.insightsNoDataYet,
                              style: TextStyle(color: scheme.outlineVariant),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _countUpController,
                            // Same one-shot count-up as the Mood Percentage
                            // rings below, applied here as the line rising
                            // from the chart's own floor (mood score 1) up
                            // to each day's real value, instead of just
                            // appearing already fully drawn.
                            builder: (context, _) {
                              final t = Curves.easeOutCubic.transform(
                                _countUpController.value,
                              );
                              final animatedValues = [
                                for (final v in values)
                                  v == null ? null : 1 + (v - 1) * t,
                              ];
                              return TrendChart(
                                values: animatedValues,
                                last7Days: last7Days,
                                scheme: scheme,
                                breathe: _breatheController,
                                enableTooltips: true,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final day in last7Days)
                          Text(
                            weekdayAbbrev(context, day),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.outlineVariant,
                            ),
                          ),
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mood.swatch,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              moodLabel(context, mood),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
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
                  Text(
                    l10n.weeklyDistributionTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (weekEntries.isEmpty)
                    Text(
                      l10n.weeklyLogMoodBreakdown,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 12,
                        // Same one-shot count-up as the Trend chart/Mood
                        // Percentage rings above — a left-to-right reveal
                        // (Align + widthFactor) rather than animating each
                        // segment's own flex, which is an int and would've
                        // jumped in whole-number steps instead of sliding
                        // smoothly. Every segment's *relative* width among
                        // each other is already correct at every point
                        // during the reveal, since the Row underneath never
                        // changes — only how much of it is shown does.
                        child: AnimatedBuilder(
                          animation: _countUpController,
                          builder: (context, child) => Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: Curves.easeOutCubic.transform(
                              _countUpController.value,
                            ),
                            child: child,
                          ),
                          child: Row(
                            children: [
                              for (final mood in Mood.values)
                                if (moodCounts[mood]! > 0)
                                  Expanded(
                                    flex: moodCounts[mood]!,
                                    child: Container(color: mood.swatch),
                                  ),
                            ],
                          ),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mood.swatch,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.weeklyMoodCount(
                                    moodLabel(context, mood),
                                    moodCounts[mood]!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weeklyMoodPercentageTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (weekEntries.isEmpty)
                    Text(
                      l10n.weeklyLogMoodBreakdown,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _MoodPercentCard(
                            icon: Icons.sentiment_satisfied_alt,
                            color: const Color(0xFF2E7D32),
                            label: l10n.weeklyPositive,
                            percent: _moodPercent(weekEntries, const [
                              Mood.great,
                              Mood.good,
                            ]),
                            countUp: _countUpController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MoodPercentCard(
                            icon: Icons.sentiment_neutral,
                            color: const Color(0xFFB45309),
                            label: l10n.weeklyNeutral,
                            percent: _moodPercent(weekEntries, const [
                              Mood.okay,
                            ]),
                            countUp: _countUpController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MoodPercentCard(
                            icon: Icons.sentiment_dissatisfied,
                            color: scheme.error,
                            label: l10n.weeklyNegative,
                            percent: _moodPercent(weekEntries, const [
                              Mood.sad,
                              Mood.awful,
                            ]),
                            countUp: _countUpController,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.weeklyKeyInsightTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight,
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What percent of this week's entries fell into the given set of
  /// moods — e.g. Positive = [great, good]. Rounds to the nearest whole
  /// percent; 0 on an empty week rather than dividing by zero.
  int _moodPercent(List<JournalEntry> weekEntries, List<Mood> moods) {
    if (weekEntries.isEmpty) return 0;
    final count = weekEntries.where((e) => moods.contains(e.mood)).length;
    return ((count / weekEntries.length) * 100).round();
  }

  /// Computed entirely locally — no API — by comparing the average mood
  /// score of entries carrying a given tag/activity against the week's
  /// overall average, for *every* tag that showed up at least twice (a
  /// one-off tag isn't a real pattern), not just picking a single
  /// "winner" by raw score first. Picking the winner by raw delta before
  /// converting to a percentage biased the old version toward whichever
  /// tag happened to be paired with the single best mood in the data,
  /// even when it was actually a fairly ordinary tag overall — computing
  /// every tag's own percentage up front and only then ranking them
  /// avoids that. Sorted best to worst; a 0% swing is dropped since it's
  /// not actually an insight about that tag either way.
  List<({String label, int count, int percent})> _computeTagInsights(
    List<JournalEntry> weekEntries,
  ) {
    if (weekEntries.length < 2) return const [];
    final overallAvg =
        weekEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) /
        weekEntries.length;
    if (overallAvg <= 0) return const [];

    final byLabel = <String, List<double>>{};
    for (final e in weekEntries) {
      for (final label in e.labels) {
        byLabel.putIfAbsent(label, () => []).add(moodScore[e.mood]!.toDouble());
      }
    }

    final results = <({String label, int count, int percent})>[];
    byLabel.forEach((label, scores) {
      if (scores.length < 2) return; // one-off tags aren't a real pattern
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      final percent = (((avg - overallAvg) / overallAvg) * 100).round();
      if (percent == 0) return;
      results.add((label: label, count: scores.length, percent: percent));
    });
    results.sort((a, b) => b.percent.compareTo(a.percent));
    return results;
  }

  /// The line shown when there's no tag with enough repeats yet to rank —
  /// buckets the week's overall average mood into a general description
  /// instead of leaving the card blank.
  String _fallbackSummary(
    BuildContext context,
    List<JournalEntry> weekEntries,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (weekEntries.isEmpty) return l10n.weeklyFallbackNoEntries;
    final overallAvg =
        weekEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) /
        weekEntries.length;
    if (overallAvg >= 4) return l10n.insightsSummaryGreatWeek;
    if (overallAvg <= 2.5) return l10n.insightsSummaryHeavierWeek;
    return l10n.weeklyFallbackSteady;
  }

  /// The single Key Insight sentence — names both the week's best- and
  /// worst-performing tag together (not just a single "winner"), so a
  /// noticeably worse tag doesn't go unmentioned just because something
  /// else happened to be better. Falls back to a plain overall-average
  /// summary when there's no tag with enough repeats yet to say anything
  /// more specific, or names just the one tag when only one qualifies.
  String _insightSentence(
    BuildContext context,
    List<JournalEntry> weekEntries,
    List<({String label, int count, int percent})> tagInsights,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (tagInsights.isEmpty) return _fallbackSummary(context, weekEntries);

    String phrase(({String label, int count, int percent}) t) =>
        l10n.weeklyInsightPhrase(
          t.percent.abs(),
          t.percent >= 0 ? 'better' : 'worse',
          activityLabel(context, t.label),
        );

    final best = tagInsights.first;
    final worst = tagInsights.last;
    if (best.label == worst.label) {
      final tail = best.percent >= 0
          ? l10n.weeklyInsightTailPositive
          : l10n.weeklyInsightTailNegative;
      return l10n.weeklyInsightSingle(phrase(best), tail);
    }
    return l10n.weeklyInsightBoth(phrase(best), phrase(worst));
  }

  void _share(
    BuildContext context,
    List<JournalEntry> weekEntries,
    Map<Mood, int> moodCounts,
    String insight,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final counts = [
      for (final mood in Mood.values)
        if (moodCounts[mood]! > 0)
          l10n.weeklyShareMoodCount(
            moodLabel(context, mood),
            moodCounts[mood]!,
          ),
    ].join(', ');
    // The native share sheet backgrounds this app the same way switching
    // away to another app does — see ExternalActivityGuard's own doc for
    // why this stops that from being mistaken for actually leaving and
    // re-locking the app (if Pattern Lock is on) the moment it returns.
    ExternalActivityGuard.begin();
    Share.share(
      '${l10n.weeklyShareIntro}\n\n$counts\n\n$insight',
      subject: l10n.weeklyDetailTitle,
    ).whenComplete(ExternalActivityGuard.end);
  }
}

/// One "MOOD PERCENTAGE" stat — a ring showing the percent filled, an
/// icon centered inside it, then the number and label underneath.
/// Structurally the same idea as a fitness app's steps/calories/activity
/// ring row, adapted to this app's own light card styling rather than a
/// literal copy of a dark-themed reference.
class _MoodPercentCard extends StatelessWidget {
  const _MoodPercentCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.percent,
    required this.countUp,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int percent;

  /// Drives the ring and the number counting up from 0 to [percent] once,
  /// when the screen first opens — shared across all three cards (see
  /// _WeeklyDetailScreenState._countUpController) so they animate in
  /// together rather than each restarting on its own.
  final Animation<double> countUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedBuilder(
        animation: countUp,
        builder: (context, _) {
          // Curved rather than a bare linear countUp.value — eases the
          // count-up/ring-fill to a stop instead of it feeling mechanical.
          final shown = (percent * Curves.easeOutCubic.transform(countUp.value))
              .round();
          return Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: shown / 100,
                      strokeWidth: 4,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Icon(icon, size: 20, color: color),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$shown%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}
