import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../screens/settings_screen.dart';

/// The `<header>` shared by every screen: avatar, "Lumina" wordmark,
/// an Aura companion on/off switch, and the settings gear.
///
/// The bubble_chart button does *not* open the chat — it toggles whether
/// the floating Aura button is shown at all, same as the "Enable Aura"
/// switch on the Settings screen. To actually chat with Aura, tap the
/// floating bubble itself.
class LuminaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LuminaTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
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
              onPressed: () => appState.setAuraEnabled(!appState.auraEnabled),
              icon: Icon(
                Icons.bubble_chart,
                color: appState.auraEnabled ? scheme.primary : scheme.outlineVariant,
              ),
              tooltip: appState.auraEnabled ? 'Hide Aura companion' : 'Show Aura companion',
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
