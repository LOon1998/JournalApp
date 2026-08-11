import 'package:flutter/material.dart';
import '../screens/aura_chat_screen.dart';

/// The floating "Aura" companion button that can be dragged anywhere on
/// screen and opens the Aura chat when tapped (not dragged).
///
/// Tap and drag are both derived from the *same* pan gesture rather than
/// combining `onTap` with `onPanUpdate` on one [GestureDetector] — Flutter's
/// gesture arena tends to let the pan recognizer win on any movement at
/// all (even the sub-pixel jitter a normal mouse click has), which made
/// `onTap` silently never fire. Tracking total movement across the pan and
/// only opening the chat if it stayed under a small slop avoids that.
class AuraFab extends StatefulWidget {
  const AuraFab({super.key});

  @override
  State<AuraFab> createState() => _AuraFabState();
}

class _AuraFabState extends State<AuraFab> {
  static const _size = 56.0;
  static const _margin = 16.0;
  // Extra clearance so the default spot sits above the bottom nav bar.
  static const _bottomClearance = 96.0;
  // Total movement (px) below which a pan gesture still counts as a tap.
  static const _tapSlop = 8.0;

  Offset? _position;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.of(context).size;
    final maxX = screen.width - _size - _margin;
    final maxY = screen.height - _size - _margin - _bottomClearance;

    _position ??= Offset(maxX, maxY);
    final left = _position!.dx.clamp(_margin, maxX);
    final top = _position!.dy.clamp(_margin, maxY);

    return Positioned(
      left: left,
      top: top,
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuraChatScreen()),
            );
          }
        },
        child: Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: scheme.primary.withValues(alpha: 0.4),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(Icons.bubble_chart, color: scheme.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
