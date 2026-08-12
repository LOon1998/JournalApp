import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';

/// "Daily Check-in" mockup: quick mood + activity log, distinct from the
/// longer free-form Journal entry.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Mood? _selectedMood;
  final Set<String> _activities = {};
  bool _showCustomActivity = false;
  final _customActivityController = TextEditingController();

  static const _activityOptions = ['Work', 'Family', 'Friends', 'Hobby', 'Exercise', 'Sleep'];

  // Custom ones typed via "Other" — separate from the fixed preset
  // options above, which are always just a fixed 6, not something that
  // can keep growing. Without a cap here, this list could grow without
  // bound and push the whole screen into an ever-longer scroll.
  static const _maxCustomActivities = 8;

  // A custom activity is a short label like a tag, not a place to write —
  // same cap as Journal/Entry Detail's tag inputs, since these end up
  // merged into an entry's tags anyway (see AppState.handOffCheckInToJournal).
  static const _maxActivityLength = 15;

  @override
  void dispose() {
    _customActivityController.dispose();
    super.dispose();
  }

  bool _checkMoodAndCap(AppState appState) {
    if (_selectedMood == null) {
      showAppSnackBar(context, 'Pick a mood first \u{1F642}');
      return false;
    }
    if (appState.hasReachedDailyCap(DateTime.now())) {
      showAppSnackBar(
          context, "Today's ${AppState.maxDailyEntries}-entry limit is reached — delete one to add another.");
      return false;
    }
    return true;
  }

  void _saveAndWriteJournal() {
    final appState = AppStateScope.of(context);
    if (!_checkMoodAndCap(appState)) return;
    // Nothing is saved yet — this only stages the check-in for Journal to
    // turn into an actual entry once "Complete Entry" is pressed there.
    // Saving here too (as this used to do) was creating a duplicate entry
    // on top of whatever Journal went on to save.
    appState.handOffCheckInToJournal(_selectedMood!, _activities.toList());
    setState(() {
      _selectedMood = null;
      _activities.clear();
      _customActivityController.clear();
      _showCustomActivity = false;
    });
  }

  void _saveMoodOnly() {
    final appState = AppStateScope.of(context);
    if (!_checkMoodAndCap(appState)) return;
    // Unlike "Save & Write Journal", this commits a complete entry
    // immediately — Journal then scrolls to and briefly highlights it so
    // it's obvious exactly where the quick save landed.
    appState.addQuickEntry(_selectedMood!, _activities.toList());
    showAppSnackBar(context, 'Mood saved to your journal \u{1F4D6}');
    setState(() {
      _selectedMood = null;
      _activities.clear();
      _customActivityController.clear();
      _showCustomActivity = false;
    });
  }

  void _confirmCustomActivity() {
    final text = _customActivityController.text.trim();
    if (text.isEmpty) return;
    final customCount = _activities.where((a) => !_activityOptions.contains(a)).length;
    if (customCount >= _maxCustomActivities) {
      showAppSnackBar(context, 'Up to $_maxCustomActivities custom activities');
      return;
    }
    setState(() {
      _activities.add(text);
      _customActivityController.clear();
      _showCustomActivity = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atCap = AppStateScope.of(context).hasReachedDailyCap(DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          'How are you feeling today?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 24),
        // Explicit 3-then-2 rows rather than a Wrap — with the smaller
        // 72px circles, a Wrap fits all 5 on one row on most phone
        // widths, which isn't the layout this was designed for.
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final mood in Mood.values.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _MoodOption(
                      mood: mood,
                      selected: _selectedMood == mood,
                      // Tapping the already-selected mood again deselects it,
                      // rather than being stuck once picked.
                      onTap: () => setState(() => _selectedMood = _selectedMood == mood ? null : mood),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final mood in Mood.values.skip(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _MoodOption(
                      mood: mood,
                      selected: _selectedMood == mood,
                      onTap: () => setState(() => _selectedMood = _selectedMood == mood ? null : mood),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What have you been up to?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final activity in _activityOptions)
                    _ActivityChip(
                      label: activity,
                      selected: _activities.contains(activity),
                      onTap: () => setState(() {
                        if (!_activities.remove(activity)) _activities.add(activity);
                      }),
                    ),
                  // Custom activities typed via "Other" — without this,
                  // confirming one added it to _activities but it never
                  // appeared anywhere, so it looked like nothing happened.
                  for (final activity in _activities.where((a) => !_activityOptions.contains(a)))
                    _ActivityChip(
                      label: activity,
                      selected: true,
                      onTap: () => setState(() => _activities.remove(activity)),
                    ),
                  // Hidden once at the custom-activity cap, rather than
                  // still inviting a tap that _confirmCustomActivity
                  // would just reject with a snackbar.
                  if (_activities.where((a) => !_activityOptions.contains(a)).length < _maxCustomActivities)
                    _ActivityChip(
                      label: 'Other',
                      icon: Icons.add,
                      selected: _showCustomActivity,
                      onTap: () => setState(() => _showCustomActivity = !_showCustomActivity),
                    ),
                ],
              ),
              if (_showCustomActivity) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customActivityController,
                          autofocus: true,
                          maxLength: _maxActivityLength,
                          decoration: const InputDecoration(hintText: 'What else?', counterText: ''),
                          // Enter/"Done" on the keyboard confirms too, not
                          // just the tick.
                          onSubmitted: (_) => _confirmCustomActivity(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle, color: scheme.primary),
                        onPressed: _confirmCustomActivity,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            // Dimmed until a mood is picked (or the daily cap is
            // reached), but still tappable — a truly disabled
            // (onPressed: null) button couldn't show the reminder
            // snackbar on tap. Picking activities/tags alone doesn't
            // light the buttons up.
            child: AnimatedOpacity(
              opacity: _selectedMood == null || atCap ? 0.5 : 1,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                      ),
                      onPressed: _saveAndWriteJournal,
                      child: const Text('Continue & Write\nJournal', textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.primary),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _saveMoodOnly,
                      child: const Text('Save Mood Only'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (atCap) ...[
          const SizedBox(height: 8),
          Center(
            child: Text("Today's ${AppState.maxDailyEntries}-entry limit is reached.",
                style: TextStyle(fontSize: 12, color: scheme.error)),
          ),
        ],
      ],
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({required this.mood, required this.selected, required this.onTap});

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // Smaller than before (was 96) — more likely to fit the
              // whole check-in on one screen without scrolling, which
              // mattered more than the extra size once there could also
              // be several rows of activity chips below.
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mood.swatch.withValues(alpha: selected ? 1 : 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? mood.onSwatch : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Text(mood.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 6),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? mood.onSwatch : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: selected ? Border.all(color: scheme.primaryFixedDim, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
