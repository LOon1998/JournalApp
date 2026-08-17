import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// Small inline play/pause control with elapsed/total time for a
/// base64-encoded voice note, played straight from memory via
/// [BytesSource] — no temp file needed since the audio is embedded
/// directly in the entry. Optionally shows a delete button inline —
/// pass [onDelete] to include it (and gate it by edit mode, same as
/// everything else editable on an entry), or omit it for a read-only
/// player.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key, required this.base64Audio, this.onDelete});
  final String base64Audio;
  final VoidCallback? onDelete;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _sourceSet = false;

  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<Duration> _posSub;
  late final StreamSubscription<Duration> _durSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _posSub.cancel();
    _durSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else if (_sourceSet && _state == PlayerState.paused) {
      await _player.resume();
    } else {
      // First play, or replaying after it finished — (re)supply the
      // source; resuming a "completed" player would just replay nothing.
      // Matches whichever encoder voice_recorder_sheet.dart actually
      // recorded with — Opus/WebM on web (browsers' MediaRecorder can't
      // produce AAC), AAC/MP4 natively.
      await _player.play(
        BytesSource(base64Decode(widget.base64Audio), mimeType: kIsWeb ? 'audio/webm' : 'audio/mp4'),
      );
      _sourceSet = true;
    }
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playing = _state == PlayerState.playing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggle,
            customBorder: const CircleBorder(),
            child: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: scheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _total == Duration.zero
                ? AppLocalizations.of(context)!.voiceNoteLabel
                : '${_format(_position)} / ${_format(_total)}',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: widget.onDelete,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 20, color: scheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
