import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../services/gemini_service.dart';
import '../theme/activity_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';
import '../widgets/mood_emoji.dart';
import 'weekly_detail_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final entries = appState.entries;

    final moodCounts = <Mood, int>{};
    for (final e in entries) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
    }
    Mood? topMood;
    var topCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > topCount) {
        topCount = count;
        topMood = mood;
      }
    });

    final activityMoodBuckets = <String, List<Mood>>{};
    for (final e in entries) {
      for (final label in e.labels) {
        activityMoodBuckets.putIfAbsent(label, () => []).add(e.mood);
      }
    }
    final correlations = activityMoodBuckets.entries.map((entry) {
      final best = entry.value
          .fold<Map<Mood, int>>({}, (map, mood) {
            map[mood] = (map[mood] ?? 0) + 1;
            return map;
          })
          .entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      return MapEntry(entry.key, best);
    }).toList()
      ..sort((a, b) => activityMoodBuckets[b.key]!.length.compareTo(activityMoodBuckets[a.key]!.length));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        const _QuickCheckInCard(),
        Text('Your Mood Journey',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          "Here's how you've been feeling this week. Remember, every feeling is valid.",
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _WeeklyTrendCard(entries: entries),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final mostFrequent = FloatingCard(
              child: Column(
                children: [
                  Text('MOST FREQUENT',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.primary)),
                  const SizedBox(height: 16),
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: topMood?.swatch ?? scheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: topMood != null
                        ? MoodEmoji(mood: topMood!, size: 44)
                        : const Text('✨', style: TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 12),
                  Text(topMood?.label ?? 'None yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Recorded $topCount time${topCount == 1 ? '' : 's'} recently',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            );
            final correlationsCard = _CorrelationsCard(correlations: correlations);
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: mostFrequent),
                  const SizedBox(width: 20),
                  Expanded(child: correlationsCard),
                ],
              );
            }
            // Stretch — a plain Column (unlike the outer ListView, which
            // forces full width automatically) only sizes each child to
            // its own content's width by default, which left this card
            // narrower than every other card on the page.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [mostFrequent, const SizedBox(height: 20), correlationsCard],
            );
          },
        ),
      ],
    );
  }
}

/// Quick check-in shown at the top of Insights (now the app's first page)
/// — a shortcut to the Today tab's mood picker without leaving this
/// screen. Hides itself once there's already an entry logged today (no
/// manual dismiss — see [build]); picking an emoji expands it to reveal
/// the same "Save & Write Journal" / "Save Mood Only" pair Today's own
/// check-in offers, and tapping anywhere outside the card while nothing's
/// been saved collapses it back down rather than losing the selection
/// entirely. "Save & Write Journal" hands off to Journal exactly the way
/// Today's own check-in does (see AppState.handOffCheckInToJournal);
/// "Save Mood Only" commits immediately instead (see
/// AppState.addQuickEntry). HomeShell reacts to either signal regardless
/// of which screen triggered it, so no extra wiring is needed here to
/// make the tab switch happen.
class _QuickCheckInCard extends StatefulWidget {
  const _QuickCheckInCard();

  @override
  State<_QuickCheckInCard> createState() => _QuickCheckInCardState();
}

class _QuickCheckInCardState extends State<_QuickCheckInCard> {
  Mood? _selectedMood;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final alreadyLoggedToday = appState.entriesOn(DateTime.now()).isNotEmpty;
    if (alreadyLoggedToday) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final greeting = greetingForHour(DateTime.now().hour);

    return TapRegion(
      onTapOutside: (_) {
        if (_selectedMood != null) setState(() => _selectedMood = null);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting, ${appState.userName}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text('Ready to capture a moment?',
                style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text('How are you feeling right now?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final mood in Mood.values)
                        _EmojiButton(
                          mood: mood,
                          selected: _selectedMood == mood,
                          // Tapping the already-selected mood again
                          // deselects it, same as Today's own picker.
                          onTap: () => setState(() => _selectedMood = _selectedMood == mood ? null : mood),
                        ),
                    ],
                  ),
                  if (_selectedMood != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          // Effectively unreachable in practice — this
                          // whole card already hides itself once *any*
                          // entry exists today (see alreadyLoggedToday
                          // above), well before the 10-entry cap — but
                          // checked anyway for consistency with the other
                          // entry-creating actions.
                          if (appState.hasReachedDailyCap(DateTime.now())) {
                            showAppSnackBar(context, "Today's ${AppState.maxDailyEntries}-entry limit is reached.");
                            return;
                          }
                          // No activities from this quick picker (it's a
                          // shortcut, not the full Today form) — Journal's
                          // tags stay whatever the user adds there.
                          appState.handOffCheckInToJournal(_selectedMood!, const []);
                          setState(() => _selectedMood = null);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue & Write Journal', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(color: scheme.primary),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (appState.hasReachedDailyCap(DateTime.now())) {
                            showAppSnackBar(context, "Today's ${AppState.maxDailyEntries}-entry limit is reached.");
                            return;
                          }
                          // Unlike "Save & Write Journal", this commits a
                          // complete entry immediately — Journal then
                          // scrolls to and briefly highlights it.
                          appState.addQuickEntry(_selectedMood!, const []);
                          setState(() => _selectedMood = null);
                        },
                        child: const Text('Save Mood Only', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.mood, required this.selected, required this.onTap});
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? mood.swatch : Theme.of(context).colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: mood.onSwatch, width: 2) : null,
        ),
        child: MoodEmoji(mood: mood, size: 22),
      ),
    );
  }
}

/// "What affects your mood" card — icons next to each tile are picked by
/// Gemini (auto-triggered, same pattern as Weekly Trend) once a key's
/// available, upgrading over a plain local vocabulary match (see
/// activityIconFor) that's already shown in the meantime — so a tile is
/// never left icon-less just because no Gemini key is set.
class _CorrelationsCard extends StatefulWidget {
  const _CorrelationsCard({required this.correlations});
  final List<MapEntry<String, Mood>> correlations;

  @override
  State<_CorrelationsCard> createState() => _CorrelationsCardState();
}

class _CorrelationsCardState extends State<_CorrelationsCard> {
  Map<String, IconData>? _aiIcons;
  bool _autoTriggered = false;

  @override
  void didUpdateWidget(covariant _CorrelationsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Otherwise a stale AI icon set (or the auto-trigger guard) would
    // keep sitting there after entries actually change underneath this
    // — e.g. "Clear All Entries" wiping everything, or new entries
    // shifting which activities even show up here.
    final oldLabels = oldWidget.correlations.map((c) => c.key).toList();
    final newLabels = widget.correlations.map((c) => c.key).toList();
    if (!listEquals(oldLabels, newLabels)) {
      _aiIcons = null;
      _autoTriggered = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoTriggered || widget.correlations.isEmpty) return;
    final apiKey = resolveGeminiApiKey(AppStateScope.of(context).geminiApiKey);
    if (apiKey != null) {
      _autoTriggered = true;
      _generateIcons(apiKey);
    }
  }

  Future<void> _generateIcons(String apiKey) async {
    try {
      final labels = widget.correlations.take(3).map((c) => c.key).toList();
      final chosen = await fetchActivityIcons(apiKey, labels, activityIconVocabulary.keys.toList());
      if (!mounted) return;
      setState(() {
        _aiIcons = {
          for (final entry in chosen.entries)
            if (activityIconVocabulary[entry.value] != null) entry.key: activityIconVocabulary[entry.value]!,
        };
      });
    } on GeminiException {
      // Silent — a missing icon is a fine fallback, not worth a
      // snackbar for a purely decorative touch like this.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What affects your mood',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (widget.correlations.isEmpty)
            Text('Log a few more entries with activities to see patterns.',
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final c in widget.correlations.take(3))
              _CorrelationTile(
                activity: c.key,
                mood: c.value,
                // Gemini's pick first (it can read intent behind an
                // unusual custom tag), then a plain local vocabulary
                // match — covers most preset/common tags (Work, Family,
                // Health, ...) right away with no AI call needed — and
                // finally the generic tag icon so even a completely
                // custom, unrecognized tag never sits with no icon at all.
                icon: _aiIcons?[c.key] ?? activityIconFor(c.key) ?? fallbackActivityIcon,
              ),
        ],
      ),
    );
  }
}

class _CorrelationTile extends StatelessWidget {
  const _CorrelationTile({required this.activity, required this.mood, this.icon});
  final String activity;
  final Mood mood;

  /// Gemini's pick from the fixed icon vocabulary for this activity, with
  /// a plain local vocabulary match as the fallback when there's no
  /// Gemini connection (or it hasn't resolved yet, or found no good
  /// match), and [fallbackActivityIcon] as the last resort after that —
  /// see the call site in [_CorrelationsCardState]. Nullable only because
  /// this widget doesn't itself enforce that its one caller always
  /// supplies one of the three; in practice a tile is never left with no
  /// icon at all.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: mood.swatch, child: MoodEmoji(mood: mood, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: scheme.onSurface, fontSize: 14, fontFamily: 'Quicksand'),
                children: [
                  const TextSpan(text: 'You feel '),
                  TextSpan(
                      text: mood.label, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                  const TextSpan(text: ' when you\n'),
                  TextSpan(
                      text: activity,
                      style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // AI-chosen icon once connected to Gemini; left blank
          // otherwise, rather than a generic placeholder standing in for
          // something that isn't actually tailored to this activity.
          if (icon != null) Icon(icon, color: scheme.primary, size: 18),
        ],
      ),
    );
  }
}

/// The Weekly Trend mood chart. Always shows *something* useful with no
/// setup — the line plots a local, purely-arithmetic average of whichever
/// mood was tapped each day, no API involved. If a Gemini API key is
/// saved in Settings, the sparkle button lets you swap that in for a
/// Gemini-refined score per day that also reads the tone of what was
/// actually written, not just the tapped mood — an on-demand upgrade
/// rather than the chart's only way of working, so a bad/missing key or a
/// failed request never leaves this card broken.
class _WeeklyTrendCard extends StatefulWidget {
  const _WeeklyTrendCard({required this.entries});
  final List<JournalEntry> entries;

  @override
  State<_WeeklyTrendCard> createState() => _WeeklyTrendCardState();
}

// Score <-> Mood, shared between the trend calculation and the chart's own
// rendering (left-axis emoji labels, per-dot mood coloring).
const moodScore = {
  Mood.great: 5,
  Mood.good: 4,
  Mood.okay: 3,
  Mood.sad: 2,
  Mood.awful: 1,
};
const scoreToMood = {5: Mood.great, 4: Mood.good, 3: Mood.okay, 2: Mood.sad, 1: Mood.awful};

String weekdayAbbrev(int weekday) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

/// The quick check-in card's greeting for the given local hour (0-23) —
/// four tiers rather than the original three, since 9pm-4am all reading
/// as "Good evening" stopped making sense the later it got.
String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 21) return 'Good evening';
  return 'Good night';
}

/// A dot's color for a given (possibly fractional/averaged) [score] —
/// rounded to the *nearest whole mood* and using that mood's exact
/// swatch, rather than blending between two moods' colors. A blended
/// in-between shade (an earlier version of this) didn't match any swatch
/// in the legend shown right below the chart, which read as broken —
/// every dot should be a color you can actually find in that legend.
Color moodColorForScore(double score) {
  final int rounded = score.round().clamp(1, 5);
  return scoreToMood[rounded]!.swatch;
}

class _WeeklyTrendCardState extends State<_WeeklyTrendCard> with SingleTickerProviderStateMixin {
  // Slow, continuous ease-in-out pulse — just enough to read as "live"
  // (the fill glowing gently, the latest dot pulsing) rather than a
  // distracting animation.
  late final _breatheController =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  // Computed fresh on every build (not cached in a field) — this card's
  // State lives for as long as the Insights tab does, which thanks to
  // HomeShell's IndexedStack is effectively the whole app session, so a
  // one-time-computed "today" would silently go stale (still showing
  // yesterday as the rightmost day) for anyone who leaves the app open
  // across midnight.
  List<DateTime> _last7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
  }

  List<double?> _localAverages(List<DateTime> last7Days) => last7Days.map((day) {
        final dayEntries = widget.entries.where((e) => e.isSameDay(day)).toList();
        if (dayEntries.isEmpty) return null;
        final avg = dayEntries.map((e) => moodScore[e.mood]!).reduce((a, b) => a + b) / dayEntries.length;
        return avg;
      }).toList();

  // Key Takeaway's default caption — computed from the local averages
  // alone (no API, no written-text analysis, just arithmetic), so there's
  // always a real, data-driven line even without a Gemini key: the
  // direction between the first and last known day decides "trending"
  // vs "steady," and the week's overall average decides which flavor of
  // steady it is.
  String _localSummary(List<double?> values) {
    final known = [
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) values[i]!,
    ];
    if (known.length < 2) return 'Log a few more moods this week to start seeing a trend.';

    final delta = known.last - known.first;
    final average = known.reduce((a, b) => a + b) / known.length;

    if (delta >= 0.75) return "Trending upward this week — nice momentum, keep it going.";
    if (delta <= -0.75) return "A tougher stretch this week — be gentle with yourself.";
    if (average >= 4) return "A genuinely great week overall — whatever you're doing, keep it up.";
    if (average <= 2.5) return "A heavier week than usual — might be worth some extra care.";
    return "Pretty steady this week — nothing dramatic either way.";
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  void _openWeeklyDetail(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WeeklyDetailScreen(entries: widget.entries)),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last7Days = _last7Days();
    final values = _localAverages(last7Days);

    return FloatingCard(
      // The whole card opens Weekly Detail now, not just the chart or just
      // the title row — no reason to make someone hunt for the one tappable
      // strip when everything on this card is a summary of the same thing.
      onTap: () => _openWeeklyDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mood Pattern',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  // The same trailing-chevron cue Settings uses for every
                  // row that opens something else.
                  Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
                ],
              ),
              // No manual sparkle button anymore — the AI-refined trend
              // (see didChangeDependencies) already generates itself
              // automatically as soon as a key's available, so a tap-to-
              // trigger button was just redundant clutter.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
                child: Text('Last 7 Days',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dots themselves aren't individually tappable here (see
          // TrendChart.enableTooltips / the IgnorePointer below) so this
          // area's tap reaches the card's own InkWell above instead of
          // fighting a per-dot tooltip for the same gesture.
          Container(
            height: 200,
            // Equal left/right padding — was 8/16, which put the first
            // and last dots at visibly different distances from their
            // respective edges.
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            // fl_chart handles its own curve smoothing/interpolation
            // properly (points sit exactly on the line, unlike the old
            // hand-rolled CustomPainter version) — needs at least one
            // real value to plot, so an all-empty week falls back to
            // plain text instead of handing it an empty spot list.
            child: values.every((v) => v == null)
                ? Center(child: Text('No data yet', style: TextStyle(color: scheme.outlineVariant)))
                : IgnorePointer(
                    child: TrendChart(values: values, last7Days: last7Days, scheme: scheme, breathe: _breatheController),
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < last7Days.length; i++)
                  Text(
                    weekdayAbbrev(last7Days[i].weekday),
                    // First and last day of the week bolded/colored to
                    // anchor the range at a glance — the middle days stay
                    // quiet since they're not the ones you'd scan for.
                    style: i == 0 || i == last7Days.length - 1
                        ? TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.primary)
                        : TextStyle(fontSize: 11, color: scheme.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Legend — the same 5 mood colors the dots themselves use, so
          // it's clear at a glance what each color on the line means
          // without having to guess or cross-reference the emoji picker.
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
          const SizedBox(height: 16),
          Divider(height: 1, color: scheme.surfaceContainerHigh),
          const SizedBox(height: 16),
          // "Key Takeaway" — the old plain caption promoted to its own
          // labeled section (icon + heading), same summary text as
          // before, just given more visual weight since it's the one
          // line most people will actually read off this card.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  // Same color as the chart's own line, tying the icon
                  // back to the graph it's summarizing.
                  border: Border.all(color: scheme.primary, width: 1.5),
                ),
                child: Icon(Icons.lightbulb_outline, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KEY TAKEAWAY',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.primary)),
                    const SizedBox(height: 4),
                    Text(
                      widget.entries.isEmpty
                          ? 'Log a mood to start seeing your trend.'
                          : _localSummary(values),
                      style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The actual fl_chart line, rebuilt each tick of [breathe] (a repeating
/// 0→1→0 animation) so the fill glows gently and the most recent day's
/// dot pulses in size — a subtle "this is live" cue rather than a fully
/// static chart.
/// The Weekly Trend line chart itself — shared between the compact card
/// on Insights (with the "breathing" live-pulse animation) and the full
/// Weekly Detail screen (static — pass a non-animating [breathe] like
/// `kAlwaysCompleteAnimation` there, since a whole dedicated screen
/// doesn't need the "this is live" cue the small embedded card does).
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.last7Days,
    required this.scheme,
    required this.breathe,
    this.enableTooltips = false,
  });

  final List<double?> values;
  final List<DateTime> last7Days;
  final ColorScheme scheme;
  final Animation<double> breathe;

  /// Tap-a-dot-to-see-its-mood tooltips — off by default (the small card
  /// embedded in Insights instead makes the whole chart a tap target to
  /// open Weekly Detail, and enabling both here would fight over the
  /// same tap). Weekly Detail's own, bigger copy of this chart turns
  /// this on instead, since there's nothing else competing for that tap
  /// there.
  final bool enableTooltips;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) FlSpot(i.toDouble(), values[i]!),
    ];
    final lastSpotIndex = spots.length - 1;

    return AnimatedBuilder(
      animation: breathe,
      builder: (context, _) {
        final t = breathe.value; // eases 0 -> 1 -> 0 continuously
        // Dark mode uses a deep forest green (the dark scheme's own
        // primaryContainer, not the light minty primary) instead of the
        // light mode's brand green — that light mint sat too close to
        // "Good"'s own dot color to tell apart at a glance, but a plain
        // grey line didn't feel like it belonged either. A darker,
        // clearly different shade of the same green family reads as
        // distinct from every (now also-darkened, see getDotPainter
        // below) mood dot without abandoning the brand color entirely.
        final isDark = scheme.brightness == Brightness.dark;
        final lineColor = isDark ? scheme.primaryContainer : scheme.primary;
        // primaryContainer already reads as the "fill" shade in both
        // modes (a pale wash in light mode, a deep forest green in dark
        // mode via the M3 dark-scheme convention of inverting container
        // tonal weight), so this one doesn't need a light/dark branch.
        // Blended partway toward the line's own (more saturated) color so
        // the fill actually reads as a solid color right under the curve,
        // the way a "dissolve" effect needs a vivid starting point to fade
        // *from* — plain primaryContainer alone was too pale to look like
        // anything was dissolving.
        final fillBase = Color.lerp(scheme.primaryContainer, lineColor, 0.45)!;
        final fillTopAlpha = 0.55 + 0.25 * t;
        // The last dot both shines (a wider, brightening ring) and
        // breathes (a modest size pulse) — kept small (4 to 6, not the
        // much bigger swing an earlier version used) since a large swing
        // in dot radius can nudge fl_chart's own layout padding as it
        // grows, which showed up as the chart's edges visibly shifting.
        final lastDotStrokeWidth = 2 + 5 * t;
        final lastDotRadius = 4 + 2 * t;
        // Blends between the line's own color and a lighter shade of it —
        // only partway (t * 0.5, not the full 0-1 range) so the brightest
        // point of the pulse stays a gentle glow instead of swinging all
        // the way to a stark, high-contrast bright color.
        final lastDotShine = Color.lerp(lineColor, isDark ? scheme.onSurface : scheme.primaryContainer, t * 0.5)!;
        return LineChart(
          LineChartData(
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            // 0 and 6 pad the real 1-5 mood range so the top/bottom dots
            // aren't flush against the chart edge, while still landing
            // gridlines/labels on whole numbers — those two just render
            // blank (no mood maps to them).
            minY: 0,
            maxY: 6,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: scheme.outlineVariant.withValues(alpha: 0.4), strokeWidth: 1),
            ),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            // Tapping/touching a dot shows which day and mood it is —
            // the dot alone doesn't say that on its own.
            lineTouchData: enableTooltips
                ? LineTouchData(
                    enabled: true,
                    // A thin dashed dropline down to the axis, but no
                    // extra indicator dot at the bottom of it — the
                    // solid version (fl_chart's default) plus an
                    // oversized dot on top of the real one read as
                    // cluttered; the real data dot is already visible.
                    getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes
                        .map((_) => TouchedSpotIndicatorData(
                              FlLine(color: lineColor.withValues(alpha: 0.6), strokeWidth: 1.5, dashArray: const [4, 4]),
                              FlDotData(show: false),
                            ))
                        .toList(),
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      getTooltipItems: (touchedSpots) => touchedSpots.map((touched) {
                        final day = last7Days[touched.x.toInt()];
                        final mood = scoreToMood[touched.y.round().clamp(1, 5)]!;
                        return LineTooltipItem(
                          '${weekdayAbbrev(day.weekday)} · ${mood.emoji} ${mood.label}',
                          TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w700, fontSize: 12),
                        );
                      }).toList(),
                    ),
                  )
                : const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                // Otherwise the smoothed curve can swing past a point's
                // actual value right around the first/last dot (and any
                // sharp peak/valley), overshooting before settling —
                // this clamps it so the line always stays anchored
                // cleanly to each real value instead.
                preventCurveOverShooting: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  // Each dot's fill is always the mood's own full-
                  // brightness pastel swatch, same in light and dark mode
                  // — darkening it in dark mode (an earlier version of
                  // this) made it blend into the dark card background
                  // instead of standing out. The line itself is already a
                  // distinct deep green ([lineColor]) so there's no
                  // ambiguity between line and dot without needing to
                  // mute the dot too. The most recent day's dot also
                  // shines with [breathe] — same size as the rest, just a
                  // glowing, brightening ring.
                  getDotPainter: (spot, percent, bar, index) {
                    // Plain, unboosted mood color — same as the legend
                    // below the chart, so the two actually match instead
                    // of the dots looking like a different, more
                    // saturated shade of the color the legend shows.
                    final moodColor = moodColorForScore(spot.y);
                    final isLast = index == lastSpotIndex;
                    return FlDotCirclePainter(
                      radius: isLast ? lastDotRadius : 4,
                      color: moodColor,
                      strokeWidth: isLast ? lastDotStrokeWidth : 2.5,
                      // Same green as the graph line itself, in both
                      // modes — no separate white-ring treatment for dark
                      // mode.
                      strokeColor: isLast ? lastDotShine : lineColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  // A "dissolve" fade rather than a plain linear one — an
                  // eased (roughly quadratic) alpha falloff across 5 stops
                  // instead of straight-line interpolation between just 2
                  // or 3. A true linear fade reads as thinning out at a
                  // constant rate the whole way down; easing it instead
                  // keeps the color looking solid for a beat right under
                  // the curve, then dissolves away increasingly quickly —
                  // much closer to how color actually looks like it's
                  // fading into nothing, rather than a flat gradient.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.15, 0.35, 0.6, 1],
                    colors: [
                      fillBase.withValues(alpha: fillTopAlpha),
                      fillBase.withValues(alpha: fillTopAlpha * 0.72),
                      fillBase.withValues(alpha: fillTopAlpha * 0.42),
                      fillBase.withValues(alpha: fillTopAlpha * 0.16),
                      fillBase.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // No implicit animation on top of the explicit per-frame
          // rebuild above — swapping duration to zero avoids fl_chart
          // fighting its own repaint every tick.
          duration: Duration.zero,
        );
      },
    );
  }
}

