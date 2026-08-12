import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/file_bytes.dart';

/// Shows a modal recording sheet (mic auto-starts on open) and returns
/// the finished voice note base64-encoded, or null if cancelled.
/// Recording is capped at 60 seconds to keep the encoded size reasonable
/// — it's embedded directly in the entry, not saved as a device file.
Future<String?> showVoiceRecorderSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (context) => const _VoiceRecorderSheet(),
  );
}

class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet();

  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  static const _maxDuration = Duration(seconds: 60);

  final _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _busy = false;
  String? _recordingPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // Was previously unguarded — any failure here (a denied permission
    // that throws instead of just returning false, an unsupported
    // encoder, the mic already in use by another app, ...) went
    // uncaught, leaving this sheet sitting frozen at 00:00 with no
    // indication anything was wrong. That's the "can't record" bug:
    // everything downstream of a failed start() was silently skipped.
    try {
      final granted = await _recorder.hasPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _error = "Microphone permission wasn't granted.");
        return;
      }
      // path_provider has no real web implementation — calling
      // getTemporaryDirectory() there throws MissingPluginException. The
      // web recorder backend hands back its own blob: URL from stop()
      // regardless of what path we pass, so a bare filename is enough.
      // AAC (native's encoder) also isn't something browsers' MediaRecorder
      // can produce — Opus is the encoder that's actually broadly
      // supported there.
      final fileName = 'lumina_voice_${DateTime.now().microsecondsSinceEpoch}';
      final path = kIsWeb ? '$fileName.webm' : '${(await getTemporaryDirectory()).path}/$fileName.m4a';
      await _recorder.start(
        RecordConfig(
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 64000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() => _recordingPath = path);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= _maxDuration) _stopAndSave();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Couldn't start recording: $e");
    }
  }

  Future<void> _stopAndSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      final bytes = path == null ? null : await readFileBytes(path);
      if (path != null) await deleteFileQuietly(path);
      if (!mounted) return;
      Navigator.of(context).pop(bytes == null || bytes.isEmpty ? null : base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Couldn't save the recording: $e";
      });
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _recorder.cancel();
    if (_recordingPath != null) await deleteFileQuietly(_recordingPath!);
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _error != null
              ? [
                  Icon(Icons.mic_off, size: 40, color: scheme.error),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                ]
              : [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.errorContainer),
                    alignment: Alignment.center,
                    child: Icon(Icons.mic, color: scheme.error, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(_formatDuration(_elapsed), style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Max 60 seconds', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(onPressed: _busy ? null : _cancel, child: const Text('Cancel')),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : _stopAndSave,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop & Save'),
                      ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }
}
