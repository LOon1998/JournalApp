import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_tour.dart';

class LuminaBottomNav extends StatelessWidget {
  const LuminaBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (icon: Icons.bar_chart, label: l10n.navInsights, tourKey: TourKeys.insightsTab, tourText: AppTour.insightsTabText),
      (icon: Icons.sentiment_satisfied, label: l10n.navToday, tourKey: TourKeys.todayTab, tourText: AppTour.todayTabText),
      (icon: Icons.menu_book, label: l10n.navJournal, tourKey: TourKeys.journalTab, tourText: AppTour.journalTabText),
      (icon: Icons.calendar_month, label: l10n.navCalendar, tourKey: TourKeys.calendarTab, tourText: AppTour.calendarTabText),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                  tourKey: items[i].tourKey,
                  tourDescription: items[i].tourText(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tourKey,
    required this.tourDescription,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Guided tour target — see lib/services/app_tour.dart. Every nav item
  /// is showcased, so this is never actually optional in practice, but
  /// kept as its own field rather than baked into build() below for
  /// clarity about what it's for.
  final GlobalKey tourKey;
  final String tourDescription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Showcase(
      key: tourKey,
      description: tourDescription,
      targetBorderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fill: selected ? 1 : 0,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
