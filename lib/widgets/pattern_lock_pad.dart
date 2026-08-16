import 'package:flutter/material.dart';

/// A drawable 3x3 dot grid for Pattern Lock — used both to set the pattern
/// (PatternLockSetupScreen) and to verify it (AppLockScreen). Dots are
/// numbered 0-8, left-to-right/top-to-bottom; dragging a finger across at
/// least two dots and lifting reports the visited order via [onComplete].
///
/// Styled to match the familiar Android/iOS pattern-lock look — a plain
/// outlined ring with a small center dot when idle, filling in solid once
/// connected, with a straight line trailing live to the finger while
/// dragging — rather than the filled-circle-plus-glow-halo look an
/// earlier version used, which read as busier/less recognizable than the
/// pattern lock people already know from their own phone.
class PatternLockPad extends StatefulWidget {
  const PatternLockPad({
    super.key,
    required this.onComplete,
    this.errorFlash = false,
    this.size = 260,
  });

  /// Fired once per completed gesture (finger lifted) with the ordered,
  /// de-duplicated list of dot indices visited — empty if fewer than 2
  /// dots were touched, since a single-dot "pattern" isn't meaningful.
  final ValueChanged<List<int>> onComplete;

  /// When toggled true (briefly, by the caller) after a failed verify,
  /// flashes the drawn path red instead of the normal accent color.
  final bool errorFlash;

  final double size;

  @override
  State<PatternLockPad> createState() => _PatternLockPadState();
}

class _PatternLockPadState extends State<PatternLockPad> {
  final List<int> _visited = [];
  Offset? _pointerPosition;

  List<Offset> _dotCenters(double size) {
    final cell = size / 3;
    return [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++) Offset(cell * col + cell / 2, cell * row + cell / 2),
    ];
  }

  int? _hitTest(Offset local, double size) {
    final centers = _dotCenters(size);
    const hitRadius = 28.0;
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - local).distance <= hitRadius) return i;
    }
    return null;
  }

  void _handlePan(Offset local) {
    final hit = _hitTest(local, widget.size);
    setState(() {
      _pointerPosition = local;
      if (hit != null && !_visited.contains(hit)) {
        _visited.add(hit);
      }
    });
  }

  void _handleEnd() {
    final result = List<int>.from(_visited);
    setState(() {
      _visited.clear();
      _pointerPosition = null;
    });
    widget.onComplete(result.length >= 2 ? result : const []);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = widget.errorFlash ? scheme.error : scheme.primary;
    return GestureDetector(
      onPanStart: (d) => _handlePan(d.localPosition),
      onPanUpdate: (d) => _handlePan(d.localPosition),
      onPanEnd: (_) => _handleEnd(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _PatternPainter(
            dotCenters: _dotCenters(widget.size),
            visited: _visited,
            pointerPosition: _pointerPosition,
            activeColor: activeColor,
            idleColor: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.dotCenters,
    required this.visited,
    required this.pointerPosition,
    required this.activeColor,
    required this.idleColor,
  });

  final List<Offset> dotCenters;
  final List<int> visited;
  final Offset? pointerPosition;
  final Color activeColor;
  final Color idleColor;

  static const _ringRadius = 16.0;
  static const _centerDotRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    // The trailing line, drawn first so the dots paint on top of it —
    // straight segments between each connected dot, continuing live to
    // wherever the finger actually is right now.
    if (visited.isNotEmpty) {
      final linePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(dotCenters[visited.first].dx, dotCenters[visited.first].dy);
      for (final i in visited.skip(1)) {
        path.lineTo(dotCenters[i].dx, dotCenters[i].dy);
      }
      if (pointerPosition != null) path.lineTo(pointerPosition!.dx, pointerPosition!.dy);
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < dotCenters.length; i++) {
      final center = dotCenters[i];
      if (visited.contains(i)) {
        // Connected: a plain filled circle — no separate glow/halo ring,
        // which is what made the earlier version look busier.
        canvas.drawCircle(center, _ringRadius, Paint()..color = activeColor);
      } else {
        // Idle: a thin outlined ring with a small solid center dot —
        // the standard pattern-lock look, rather than a single flat dot.
        canvas.drawCircle(
          center,
          _ringRadius,
          Paint()
            ..color = idleColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        // White, not idleColor like the ring around it — reads more
        // clearly as its own distinct dot rather than blending into the
        // same grey outline.
        canvas.drawCircle(center, _centerDotRadius, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.visited != visited || oldDelegate.pointerPosition != pointerPosition || oldDelegate.activeColor != activeColor;
}
