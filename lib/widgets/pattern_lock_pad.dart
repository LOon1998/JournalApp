import 'package:flutter/material.dart';

/// A drawable 3x3 dot grid for Pattern Lock — used both to set the pattern
/// (PatternLockSetupScreen) and to verify it (AppLockScreen). Dots are
/// numbered 0-8, left-to-right/top-to-bottom; dragging a finger across at
/// least two dots and lifting reports the visited order via [onComplete].
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

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (visited.isNotEmpty) {
      final path = Path()..moveTo(dotCenters[visited.first].dx, dotCenters[visited.first].dy);
      for (final i in visited.skip(1)) {
        path.lineTo(dotCenters[i].dx, dotCenters[i].dy);
      }
      if (pointerPosition != null) path.lineTo(pointerPosition!.dx, pointerPosition!.dy);
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < dotCenters.length; i++) {
      final isVisited = visited.contains(i);
      canvas.drawCircle(dotCenters[i], 10, Paint()..color = isVisited ? activeColor : idleColor);
      if (isVisited) {
        canvas.drawCircle(
          dotCenters[i],
          16,
          Paint()
            ..color = activeColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.visited != visited || oldDelegate.pointerPosition != pointerPosition || oldDelegate.activeColor != activeColor;
}
