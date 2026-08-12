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

/// Truncates [text] to at most [maxWords] whitespace-separated words,
/// appending an ellipsis when anything was cut off. Used so an "expanded"
/// preview card still shows a bounded amount of text — expanded just means
/// a taller preview, not the entry's entire body, which is what the detail
/// screen is for.
String truncateWords(String text, int maxWords) {
  final words = text.split(RegExp(r'\s+'));
  if (words.length <= maxWords) return text;
  return '${words.take(maxWords).join(' ')}...';
}
