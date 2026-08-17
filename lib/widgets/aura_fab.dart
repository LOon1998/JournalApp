import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/aura_chat_screen.dart';
import '../services/app_tour.dart';

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

  // Extra space reserved above/left of the button so the hint bubble has
  // genuine room, rather than relying on Stack overflow. A RenderBox only
  // hit-tests its children if the tap position already falls within its
  // *own* declared size — Positioned children painted outside that via
  // `clipBehavior: Clip.none` render fine but are never reachable by a
  // tap, since the parent bails out before even checking them. That was
  // the actual bug behind "the close button doesn't work": it was
  // visible, just untappable, painted outside the button's 56x56 box.
  static const _hintReserveLeft = 150.0;
  static const _hintReserveTop = 140.0;

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

    // The reserved region shifts the button's on-screen position by
    // (reserveLeft, reserveTop) relative to this bigger box's own
    // top-left — subtracting that from the outer Positioned's offset
    // keeps the button itself exactly where the drag logic above put it.
    return Positioned(
      left: left - _hintReserveLeft,
      top: top - _hintReserveTop,
      child: SizedBox(
        width: _size + _hintReserveLeft,
        height: _size + _hintReserveTop,
        child: Stack(
          children: [
            Positioned(
              left: _hintReserveLeft,
              top: _hintReserveTop,
              child: IgnorePointer(
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
                      child: Showcase(
                        key: TourKeys.auraFab,
                        description: AppTour.auraFabText(context),
                        targetShapeBorder: const CircleBorder(),
                        child: Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          elevation: 6,
                          shadowColor: scheme.primary.withValues(alpha: 0.4),
                          child: SizedBox(
                            width: _size,
                            height: _size,
                            child: Icon(Icons.bubble_chart, color: scheme.onPrimary, size: 26),
                          ),
                        ),
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
    return Stack(
          children: [
            // Padded in by the same 8px the close button below sits at,
            // so that button lands inside this Stack's own bounds
            // instead of overflowing it — see the reserved-space comment
            // on _AuraFabState for why that matters for tappability, not
            // just how it looks.
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Material(
                  color: scheme.primaryContainer,
                  // An actual speech-bubble shape (rounded body + a small
                  // tail) instead of a plain rounded rectangle — the tail
                  // points down toward the FAB this hint belongs to,
                  // rather than looking like a random floating card.
                  shape: const _SpeechBubbleShape(tailSize: 10),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                    child: Text(
                      AppLocalizations.of(context)!.auraHintBubble,
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
            ),
            // Overlaps the bubble's corner rather than sitting inline
            // with the text — stays a deliberate, separate tap target,
            // and it's now the *only* way this hint ever goes away (no
            // more auto-dismiss timer).
            Positioned(
              top: 0,
              right: 0,
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
        );
  }
}

/// A rounded rectangle with a small triangular tail poking out of the
/// bottom-right corner, pointing down toward whatever this bubble is
/// anchored to — used instead of layering a separately-rotated square
/// under the bubble (the previous approach), which didn't get its own
/// matching shadow/elevation and never quite lined up with the body.
class _SpeechBubbleShape extends ShapeBorder {
  const _SpeechBubbleShape({this.tailSize = 10});
  final double tailSize;

  static const _radius = 20.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final bodyRect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - tailSize);
    final path = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(_radius)));
    final tailPath = Path()
      ..moveTo(rect.right - _radius - tailSize, bodyRect.bottom)
      ..lineTo(rect.right - _radius, bodyRect.bottom + tailSize)
      ..lineTo(rect.right - _radius, bodyRect.bottom)
      ..close();
    return Path.combine(PathOperation.union, path, tailPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
