import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../widgets/pattern_lock_pad.dart';

/// The unlock gate main.dart shows in front of the real app whenever
/// Pattern Lock is enabled — on cold start, and again every time the app
/// resumes from the background. main.dart only ever shows this when
/// AppLockService.isLockEnabled() is true, which now just means a
/// pattern is set, so there's always something valid to draw here.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.uid, required this.onUnlocked});

  final String uid;
  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late final _lockService = AppLockService(widget.uid);

  bool _errorFlash = false;
  String? _error;

  Future<void> _handlePattern(List<int> pattern) async {
    if (pattern.isEmpty) return;
    final ok = await _lockService.verifyPattern(pattern);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorFlash = true;
        _error = 'Incorrect pattern — try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/branding/logoIcon.png', width: 56, height: 56),
              const SizedBox(height: 12),
              Text('Moodlet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),
              Text(
                _error ?? 'Draw your pattern to unlock',
                style: TextStyle(color: _error != null ? scheme.error : null, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              PatternLockPad(
                errorFlash: _errorFlash,
                onComplete: (pattern) {
                  if (_errorFlash) setState(() => _errorFlash = false);
                  _handlePattern(pattern);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
