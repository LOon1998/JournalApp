import 'package:flutter/material.dart';

/// A single Writing Theme color circle — shared by Journal's composer and
/// the entry detail screen's own theme picker (shown in edit mode), so an
/// existing entry's theme can be changed after the fact too, not just set
/// once at creation.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({super.key, required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.primary : scheme.surfaceContainerHighest, width: selected ? 3 : 2),
        ),
      ),
    );
  }
}
