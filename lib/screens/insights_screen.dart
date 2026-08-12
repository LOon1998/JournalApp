import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _moodScore = {
    Mood.great: 5,
    Mood.good: 4,
    Mood.okay: 3,
    Mood.sad: 2,
    Mood.awful: 1,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final entries = appState.entries;
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    final dailyAverages = last7Days.map((day) {
      final dayEntries = entries.where((e) => e.isSameDay(day)).toList();
      if (dayEntries.isEmpty) return null;
      final avg = dayEntries.map((e) => _moodScore[e.mood]!).reduce((a, b) => a + b) / dayEntries.length;
      return avg;
    }).toList();

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
        FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration:
                        BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
                    child: Text('Last 7 Days',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(
                  painter: _TrendPainter(dailyAverages, scheme.primary, scheme.primaryContainer, scheme.outlineVariant),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final day in last7Days)
                    Text(_weekdayLetter(day.weekday),
                        style: TextStyle(fontSize: 11, color: scheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entries.isEmpty
                    ? 'Log a mood to start seeing your trend.'
                    : "You've been feeling steady this week — keep checking in.",
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
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
                    child: Text(topMood?.emoji ?? '✨', style: const TextStyle(fontSize: 44)),
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
            final correlationsCard = FloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What helps you shine',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  if (correlations.isEmpty)
                    Text('Log a few more entries with activities to see patterns.',
                        style: TextStyle(color: scheme.onSurfaceVariant))
                  else
                    for (final c in correlations.take(3))
                      _CorrelationTile(activity: c.key, mood: c.value),
                ],
              ),
            );
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
            return Column(children: [mostFrequent, const SizedBox(height: 20), correlationsCard]);
          },
        ),
      ],
    );
  }

  static String _weekdayLetter(int weekday) => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}

/// Quick check-in shown at the top of Insights (now the app's first page)
/// — a shortcut to the Today tab's mood picker without leaving this
/// screen. Hides itself once there's already an entry logged today (no
/// manual dismiss — see [build]); picking an emoji expands it to reveal
/// "Save & Journal", and tapping anywhere outside the card while nothing's
/// been saved collapses it back down rather than losing the selection
/// entirely. Tapping "Save & Journal" hands off to Journal exactly the way
/// Today's own check-in does (see AppState.handOffCheckInToJournal);
/// HomeShell reacts to that same signal regardless of which screen
/// triggered it, so no extra wiring is needed here to make the tab switch
/// happen.
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

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
                          onTap: () => setState(() => _selectedMood = mood),
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
                          // No activities from this quick picker (it's a
                          // shortcut, not the full Today form) — Journal's
                          // tags stay whatever the user adds there.
                          appState.handOffCheckInToJournal(_selectedMood!, const []);
                          setState(() => _selectedMood = null);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Save & Journal', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
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
        child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _CorrelationTile extends StatelessWidget {
  const _CorrelationTile({required this.activity, required this.mood});
  final String activity;
  final Mood mood;

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
          CircleAvatar(radius: 22, backgroundColor: mood.swatch, child: Text(mood.emoji)),
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
                  TextSpan(text: activity, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
          ),
          Icon(Icons.favorite, color: scheme.primaryFixedDim, size: 18),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.lineColor, this.fillColor, this.gridColor);

  final List<double?> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in [0.15, 0.5, 0.85]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    final known = values.where((v) => v != null).cast<double>().toList();
    if (known.isEmpty) return;
    final minV = known.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxV = known.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = (maxV - minV).clamp(1, 10);

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final x = size.width * (i / (values.length - 1));
      if (v == null) continue;
      final y = size.height - ((v - minV) / range) * size.height;
      points.add(Offset(x, y));
    }
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, 5, Paint()..color = lineColor);
      }
      return;
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor.withValues(alpha: 0.5), fillColor.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 5, Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}
