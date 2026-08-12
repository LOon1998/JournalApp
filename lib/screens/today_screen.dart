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

  @override
  void dispose() {
    _customActivityController.dispose();
    super.dispose();
  }

  void _save() {
    final mood = _selectedMood;
    if (mood == null) {
      showAppSnackBar(context, 'Pick a mood first \u{1F642}');
      return;
    }
    // Nothing is saved yet — this only stages the check-in for Journal to
    // turn into an actual entry once "Complete Entry" is pressed there.
    // Saving here too (as this used to do) was creating a duplicate entry
    // on top of whatever Journal went on to save.
    AppStateScope.of(context).handOffCheckInToJournal(mood, _activities.toList());
    setState(() {
      _selectedMood = null;
      _activities.clear();
      _customActivityController.clear();
      _showCustomActivity = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final mood in Mood.values)
              _MoodOption(
                mood: mood,
                selected: _selectedMood == mood,
                onTap: () => setState(() => _selectedMood = mood),
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
                          decoration: const InputDecoration(hintText: 'What else?'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle, color: scheme.primary),
                        onPressed: () {
                          final text = _customActivityController.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            _activities.add(text);
                            _customActivityController.clear();
                            _showCustomActivity = false;
                          });
                        },
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
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ),
        ),
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
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mood.swatch.withValues(alpha: selected ? 1 : 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? mood.onSwatch : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Text(mood.emoji, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 8),
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
