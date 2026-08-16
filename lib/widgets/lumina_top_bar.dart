import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../screens/settings_screen.dart';

/// The `<header>` shared by every screen: the signed-in user's photo and
/// name on the left, the "Lumina" wordmark centered (regardless of how
/// wide the left/right content is — see the two equal-flex [Expanded]s
/// below, the standard trick for a true center between unequal sides), an
/// Aura companion on/off switch, and the settings gear on the right.
///
/// The bubble_chart button does *not* open the chat — it toggles whether
/// the floating Aura button is shown at all, same as the "Enable Aura"
/// switch on the Settings screen. To actually chat with Aura, tap the
/// floating bubble itself.
class LuminaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LuminaTopBar({super.key});

  // A few px taller than before (was 64) specifically to fit the extra
  // bottom padding below — every screen's body starts right at this
  // widget's bottom edge, and the old height left almost no breathing
  // room between the header and whatever a screen put right underneath
  // it (a page title, "Today's Entries", ...), which read as cramped.
  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);

    void openSettings() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );

    return SafeArea(
      bottom: false,
      child: Padding(
        // Asymmetric on purpose — the extra room (was a plain
        // `vertical: 8`) is added only at the bottom, since that's the
        // edge that actually needed the gap; the top stays as tight
        // against the status bar/notch as it always was.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: openSettings,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: appState.profilePhotoBase64 != null
                            ? MemoryImage(base64Decode(appState.profilePhotoBase64!))
                            : null,
                        child: appState.profilePhotoBase64 == null
                            ? Icon(Icons.self_improvement, size: 18, color: scheme.onPrimaryContainer)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          appState.userName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'Lumina',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.4,
                color: scheme.primary,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => appState.setAuraEnabled(!appState.auraEnabled),
                      icon: Icon(
                        Icons.bubble_chart,
                        color: appState.auraEnabled ? scheme.primary : scheme.outlineVariant,
                      ),
                      tooltip: appState.auraEnabled ? 'Hide Aura companion' : 'Show Aura companion',
                    ),
                    IconButton(
                      onPressed: openSettings,
                      icon: Icon(Icons.settings, color: scheme.primary),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
