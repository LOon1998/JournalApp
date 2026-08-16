import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pattern_lock_pad.dart';

/// Draw-once-then-confirm flow for setting a new Pattern Lock, reached
/// from Privacy & Security. Pops with `true` if a pattern was saved, so
/// the caller can refresh its "Pattern Lock" row state.
class PatternLockSetupScreen extends StatefulWidget {
  const PatternLockSetupScreen({super.key, required this.uid});

  final String uid;

  @override
  State<PatternLockSetupScreen> createState() => _PatternLockSetupScreenState();
}

enum _Stage { draw, confirm }

class _PatternLockSetupScreenState extends State<PatternLockSetupScreen> {
  late final _lockService = AppLockService(widget.uid);
  _Stage _stage = _Stage.draw;
  List<int>? _firstPattern;
  bool _errorFlash = false;
  String _instruction = 'Draw a new pattern';

  void _handleComplete(List<int> pattern) {
    if (pattern.isEmpty) {
      setState(() {
        _errorFlash = true;
        _instruction = 'Connect at least 2 dots — try again';
      });
      return;
    }

    if (_stage == _Stage.draw) {
      setState(() {
        _firstPattern = pattern;
        _stage = _Stage.confirm;
        _errorFlash = false;
        _instruction = 'Draw the pattern again to confirm';
      });
      return;
    }

    // _stage == confirm
    if (_listEquals(pattern, _firstPattern!)) {
      _save();
    } else {
      setState(() {
        _stage = _Stage.draw;
        _firstPattern = null;
        _errorFlash = true;
        _instruction = "Patterns didn't match — draw a new pattern";
      });
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _save() async {
    await _lockService.setPattern(_firstPattern!);
    if (!mounted) return;
    showAppSnackBar(context, 'Pattern Lock set');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Set Pattern Lock')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pattern, size: 40, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                _instruction,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _errorFlash ? scheme.error : null,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PatternLockPad(
                errorFlash: _errorFlash,
                onComplete: (pattern) {
                  if (_errorFlash) setState(() => _errorFlash = false);
                  _handleComplete(pattern);
                },
              ),
              const SizedBox(height: 24),
              if (_stage == _Stage.confirm)
                TextButton(
                  onPressed: () => setState(() {
                    _stage = _Stage.draw;
                    _firstPattern = null;
                    _errorFlash = false;
                    _instruction = 'Draw a new pattern';
                  }),
                  child: const Text('Start Over'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
