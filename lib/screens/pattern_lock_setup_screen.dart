import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
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

/// Kept as an enum (rather than storing the literal localized String
/// directly) since the instruction is set from callbacks that don't have
/// a BuildContext handy — build() maps this to the right AppLocalizations
/// getter instead.
enum _Instruction { drawNew, connectDots, confirmAgain, didntMatch }

class _PatternLockSetupScreenState extends State<PatternLockSetupScreen> {
  late final _lockService = AppLockService(widget.uid);
  _Stage _stage = _Stage.draw;
  List<int>? _firstPattern;
  bool _errorFlash = false;
  _Instruction _instruction = _Instruction.drawNew;

  void _handleComplete(List<int> pattern) {
    if (pattern.isEmpty) {
      setState(() {
        _errorFlash = true;
        _instruction = _Instruction.connectDots;
      });
      return;
    }

    if (_stage == _Stage.draw) {
      setState(() {
        _firstPattern = pattern;
        _stage = _Stage.confirm;
        _errorFlash = false;
        _instruction = _Instruction.confirmAgain;
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
        _instruction = _Instruction.didntMatch;
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
    showAppSnackBar(context, AppLocalizations.of(context)!.patternLockSetSnackbar);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final instructionText = switch (_instruction) {
      _Instruction.drawNew => l10n.patternLockDrawNew,
      _Instruction.connectDots => l10n.patternLockConnectDots,
      _Instruction.confirmAgain => l10n.patternLockDrawAgainConfirm,
      _Instruction.didntMatch => l10n.patternLockDidntMatch,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.patternLockSetupTitle)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pattern, size: 40, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                instructionText,
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
                    _instruction = _Instruction.drawNew;
                  }),
                  child: Text(l10n.actionStartOver),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
