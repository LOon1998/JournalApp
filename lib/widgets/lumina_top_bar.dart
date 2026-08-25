import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../data/app_state.dart';
import '../screens/settings_screen.dart';
import '../services/app_tour.dart';

/// The `<header>` shared by every screen, in one of two layouts:
///
/// - Insights ([showAvatar] false): the full Moodlet logo mark +
///   wordmark, left-aligned, since Insights already opens with its own
///   "Welcome back" card showing the signed-in user's photo/name right
///   below — repeating either here too would just be redundant.
/// - Every other tab ([showAvatar] true): just the signed-in user's
///   photo + name on the left — no logo mark here at all (that's
///   Insights' job; repeating it on every single screen read as
///   cluttered rather than reinforcing the brand).
///
/// Both layouts end with an Aura companion on/off switch + the settings
/// gear on the right.
///
/// The bubble_chart button does *not* open the chat — it toggles whether
/// the floating Aura button is shown at all, same as the "Enable Aura"
/// switch on the Settings screen. To actually chat with Aura, tap the
/// floating bubble itself.
class LuminaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LuminaTopBar({super.key, this.showAvatar = true});

  /// Off only on Insights — see the class doc comment.
  final bool showAvatar;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);

    void openSettings() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );

    final avatarAndName = GestureDetector(
      onTap: openSettings,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Same ring treatment as the "Welcome back" card's own avatar.
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.primary, width: 2)),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: appState.profilePhotoBytes != null ? MemoryImage(appState.profilePhotoBytes!) : null,
              child: appState.profilePhotoBytes == null
                  ? Icon(Icons.person, size: 22, color: scheme.onPrimaryContainer)
                  : null,
            ),
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
    );

    final auraAndSettingsIcons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Showcase(
          key: TourKeys.auraToggleIcon,
          description: AppTour.auraToggleText(context),
          targetShapeBorder: const CircleBorder(),
          // No `tooltip:` here either — same RawTooltipState/ticker
          // collision as the Settings icon below when a native Tooltip
          // is nested directly inside a Showcase target.
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => appState.setAuraEnabled(!appState.auraEnabled),
            icon: Icon(
              Icons.bubble_chart,
              color: appState.auraEnabled ? scheme.primary : scheme.outlineVariant,
            ),
          ),
        ),
        Showcase(
          key: TourKeys.settingsIcon,
          description: AppTour.settingsIconText(context),
          targetShapeBorder: const CircleBorder(),
          // No `tooltip:` on this IconButton (unlike a plain one) — a
          // native Tooltip nested directly inside a Showcase target
          // collides with showcaseview's own overlay clone of the same
          // subtree: Flutter's RawTooltipState ends up asked for a
          // second AnimationController on a SingleTickerProviderStateMixin
          // that only supports one, crashing with "multiple tickers were
          // created". The tour's own description already explains this
          // icon while it's showing; outside the tour the gear is
          // self-explanatory enough without a hover tooltip.
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: openSettings,
            icon: Icon(Icons.settings, color: scheme.primary),
          ),
        ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        // Asymmetric on purpose — bottom still gets a bit more than top
        // (was a plain `vertical: 8`), since that's the edge that needs
        // the gap toward whatever a screen puts right underneath it.
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: showAvatar
            ? Row(
                children: [
                  Expanded(child: Align(alignment: Alignment.centerLeft, child: avatarAndName)),
                  auraAndSettingsIcons,
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // logo.png (icon + "Moodlet" + subtitle all baked
                      // into one image) — Insights only.
                      child: SizedBox(
                        height: 48,
                        child: Image.asset('assets/branding/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  auraAndSettingsIcons,
                ],
              ),
      ),
    );
  }
}
