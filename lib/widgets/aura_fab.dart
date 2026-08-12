import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../screens/aura_chat_screen.dart';

/// The floating "Aura" companion button that can be dragged anywhere within
/// [bounds] and opens the Aura chat when tapped (not dragged).
///
/// [bounds] must be the actual size of the Scaffold body it's positioned
/// in (get it from a [LayoutBuilder] wrapping the containing [Stack]) —
/// not [MediaQuery]'s screen size. The full window size includes the
/// AppBar and bottom nav bar, which aren't part of the body's coordinate
/// space, so using it let the button be dragged down until it sat behind
/// the bottom nav bar.
///
/// Tap and drag are both derived from the *same* pan gesture rather than
/// combining `onTap` with `onPanUpdate` on one [GestureDetector] — Flutter's
/// gesture arena tends to let the pan recognizer win on any movement at
/// all (even the sub-pixel jitter a normal mouse click has), which made
/// `onTap` silently never fire. Tracking total movement across the pan and
/// only opening the chat if it stayed under a small slop avoids that.
///
/// This widget must always stay mounted (never conditionally built with
/// `if (enabled) AuraFab(...)`, and never wrapped in `Offstage` — see
/// [enabled]'s doc) — that's what lets its dragged-to position survive
/// being toggled off and back on.
class AuraFab extends StatefulWidget {
  const AuraFab({super.key, required this.bounds, required this.enabled});

  final Size bounds;

  /// Whether the button should currently be visible/interactive. Hiding is
  /// done *inside* this widget's build (opacity + ignoring pointer events)
  /// rather than by the caller wrapping/omitting this widget, for two
  /// reasons: (1) [Positioned] — which this widget returns — must be a
  /// direct child of the [Stack] it's laid out in, with no other
  /// [RenderObjectWidget] (including [Offstage]) in between, or Flutter
  /// throws "Incorrect use of ParentDataWidget"; and (2) keeping this
  /// widget's [State] alive across toggles is what preserves its dragged
  /// position instead of resetting to the default corner every time.
  final bool enabled;

  @override
  State<AuraFab> createState() => _AuraFabState();
}

class _AuraFabState extends State<AuraFab> with SingleTickerProviderStateMixin {
  static const _size = 56.0;
  static const _margin = 16.0;
  // Total movement (px) below which a pan gesture still counts as a tap.
  static const _tapSlop = 8.0;

  Offset? _position;
  double _dragDistance = 0;

  // Slow pulse on the button itself, only while the hint hasn't been
  // dismissed yet — draws the eye without a timer that hides the hint on
  // its own. It only ever stops because the user tapped its ✕, not
  // because time ran out.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _pulseOpacity =
      Tween(begin: 1.0, end: 0.55).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);

    final rawMaxX = widget.bounds.width - _size - _margin;
    final rawMaxY = widget.bounds.height - _size - _margin;
    final maxX = rawMaxX < _margin ? _margin : rawMaxX;
    final maxY = rawMaxY < _margin ? _margin : rawMaxY;

    _position ??= Offset(maxX, maxY);
    final left = _position!.dx.clamp(_margin, maxX);
    final top = _position!.dy.clamp(_margin, maxY);

    final showHint = widget.enabled && !appState.hasSeenAuraHint;
    // .repeat()/.stop() are no-ops when already in that state, so it's
    // safe to just assert the animation's desired state on every build
    // rather than diffing against the previous one.
    if (showHint) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    return Positioned(
      left: left,
      top: top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            ignoring: !widget.enabled,
            child: AnimatedOpacity(
              opacity: widget.enabled ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => _dragDistance = 0,
                onPanUpdate: (details) {
                  setState(() {
                    _dragDistance += details.delta.distance;
                    _position = Offset(
                      (_position!.dx + details.delta.dx).clamp(_margin, maxX),
                      (_position!.dy + details.delta.dy).clamp(_margin, maxY),
                    );
                  });
                },
                onPanEnd: (_) {
                  if (_dragDistance < _tapSlop) {
                    appState.dismissAuraHint();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuraChatScreen()),
                    );
                  }
                },
                child: FadeTransition(
                  opacity: _pulseOpacity,
                  child: Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: scheme.primary.withValues(alpha: 0.4),
                    child: SizedBox(
                      width: _size,
                      height: _size,
                      child: Icon(Icons.chat_bubble_rounded, color: scheme.onPrimary, size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showHint)
            Positioned(
              bottom: _size + 12,
              right: 0,
              child: _HintBubble(onDismiss: appState.dismissAuraHint),
            ),
        ],
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Material(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Need to talk? I'm here for you.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            // Overlaps the bubble's corner rather than sitting inline
            // with the text — stays a deliberate, separate tap target,
            // and it's now the *only* way this hint ever goes away (no
            // more auto-dismiss timer).
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: scheme.surfaceContainerLowest,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: onDismiss,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.close, size: 14, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Small triangle pointing down at the FAB.
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(width: 10, height: 10, color: scheme.primaryContainer),
          ),
        ),
      ],
    );
  }
}
