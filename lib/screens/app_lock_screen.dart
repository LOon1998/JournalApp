import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../widgets/pattern_lock_pad.dart';

enum _Stage { loading, biometricPrompt, pattern, biometricRetry }

/// The unlock gate main.dart shows in front of the real app whenever
/// Fingerprint Unlock and/or Pattern Lock is enabled — on cold start, and
/// again every time the app resumes from the background. Tries biometrics
/// first if it's enabled and the device actually has it available,
/// falling back to the pattern pad only if one is actually set — a failed
/// biometric prompt with no pattern configured stays on a "try again"
/// state instead of showing a pattern pad that could never succeed.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.uid, required this.onUnlocked});

  final String uid;
  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late final _lockService = AppLockService(widget.uid);

  _Stage _stage = _Stage.loading;
  bool _biometricAvailable = false;
  bool _hasPattern = false;
  bool _errorFlash = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final biometricEnabled = await _lockService.isBiometricEnabled();
    final biometricAvailable = biometricEnabled && await _lockService.isBiometricAvailable();
    final hasPattern = await _lockService.hasPattern();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = biometricAvailable;
      _hasPattern = hasPattern;
    });
    if (biometricAvailable) {
      _tryBiometric();
    } else {
      setState(() => _stage = _Stage.pattern);
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _stage = _Stage.biometricPrompt);
    final ok = await _lockService.authenticateWithBiometrics();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
      return;
    }
    // Failed or cancelled prompt: fall back to the pattern pad only if one
    // is actually set — otherwise there'd be nothing valid to draw, so
    // stay on a state that just offers to retry fingerprint instead.
    setState(() => _stage = _hasPattern ? _Stage.pattern : _Stage.biometricRetry);
  }

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
              Icon(Icons.self_improvement, size: 48, color: scheme.primary),
              const SizedBox(height: 12),
              Text('Lumina', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),
              ..._buildBody(scheme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(ColorScheme scheme) {
    switch (_stage) {
      case _Stage.loading:
        return const [CircularProgressIndicator()];
      case _Stage.biometricPrompt:
        return const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Verifying...'),
        ];
      case _Stage.biometricRetry:
        return [
          Text("Couldn't verify your fingerprint", style: TextStyle(fontWeight: FontWeight.w600, color: scheme.error)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _tryBiometric,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Try Again'),
          ),
        ];
      case _Stage.pattern:
        return [
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
          if (_biometricAvailable) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use Fingerprint Instead'),
            ),
          ],
        ];
    }
  }
}
