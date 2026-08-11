import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

/// The `<header>` shared by every screen: avatar, "Lumina" wordmark,
/// Aura shortcut, settings gear.
class LuminaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LuminaTopBar({super.key, this.onAuraTap});

  final VoidCallback? onAuraTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.self_improvement, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lumina',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.4,
                  color: scheme.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: onAuraTap,
              icon: Icon(Icons.bubble_chart, color: scheme.primary),
              tooltip: 'Aura',
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: Icon(Icons.settings, color: scheme.primary),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
