import 'package:flutter/material.dart';

/// Small rounded label chip used to show an entry's tags/activities on
/// both the Journal timeline and the Calendar day detail.
class MiniChip extends StatelessWidget {
  const MiniChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Plain white in light mode rather than the greyish
    // surfaceContainerLowest — reads cleaner against the mood-tinted card
    // backgrounds these sit on. Dark mode keeps the theme-aware surface
    // color, since white would be jarring there.
    final chipColor = scheme.brightness == Brightness.light ? Colors.white : scheme.surfaceContainerLowest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
