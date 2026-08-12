import 'package:flutter/material.dart';

/// Whether [text] would need more than one line to display at [style]
/// within [maxWidth] — used to decide whether an entry's expand/collapse
/// chevron has anything to actually reveal, rather than showing it
/// whenever there's *any* text, even a one-liner short enough to never
/// wrap or truncate in the first place.
bool textOverflowsOneLine(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return painter.didExceedMaxLines;
}
