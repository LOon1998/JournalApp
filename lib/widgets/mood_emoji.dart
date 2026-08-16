import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lottie;
import '../theme/app_theme.dart';

/// Google's animated Noto Emoji, fetched live from the same CDN Google
/// itself serves emoji-picker animations from — used in place of a plain
/// static emoji glyph for whichever moods are listed below. Any mood not
/// listed still renders its plain emoji text exactly as before, so this
/// is a drop-in replacement wherever `Text(mood.emoji, ...)` used to be.
const _animatedMoodUrls = <Mood, String>{
  Mood.great: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f929/lottie.json',
  Mood.good: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60e/lottie.json',
  Mood.okay: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f610/lottie.json',
  Mood.awful: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f629/lottie.json',
  Mood.sad: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f622/lottie.json',
};

/// Renders a mood's emoji at the given [size] (matching the font size the
/// plain-text version used) — animated via Lottie for whichever moods
/// have an entry in [_animatedMoodUrls], plain emoji text for the rest.
/// Falls back to the plain emoji automatically if the animation fails to
/// load (offline, blocked, slow network, ...) so nothing ever breaks or
/// sits blank waiting on a network fetch that isn't going to succeed.
class MoodEmoji extends StatelessWidget {
  const MoodEmoji({super.key, required this.mood, required this.size, this.animate = true});

  final Mood mood;
  final double size;

  /// Lets a caller with its own notion of "selected" (like Today's mood
  /// picker) show every option's plain emoji and only actually animate
  /// the one currently picked — a whole row of things all quietly
  /// looping at once reads as busier and less meaningful than one clear
  /// motion cue on the thing that's actually selected. True everywhere
  /// else (the default), since most call sites don't have a selection
  /// state to key off in the first place.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final url = animate ? _animatedMoodUrls[mood] : null;
    if (url == null) {
      return Text(mood.emoji, style: TextStyle(fontSize: size));
    }
    return lottie.Lottie.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(mood.emoji, style: TextStyle(fontSize: size)),
      // A blank gap while the animation is still loading would flash
      // awkwardly in a list of otherwise-instant plain-text emoji: show
      // the plain emoji immediately and let it get replaced once the
      // animation is actually ready.
      frameBuilder: (context, child, composition) {
        if (composition == null) return Text(mood.emoji, style: TextStyle(fontSize: size));
        return child;
      },
    );
  }
}
