import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../l10n/generated/app_localizations.dart';

/// GlobalKeys for every widget the first-run guided tour highlights.
/// Defined once here (rather than locally inside each screen) so both
/// [AppTour]'s own orchestration and each target screen's
/// `Showcase(key: TourKeys.xxx, ...)` wrapper reference the exact same
/// key.
class TourKeys {
  TourKeys._();

  static final insightsTab = GlobalKey(debugLabel: 'tourInsightsTab');
  static final todayTab = GlobalKey(debugLabel: 'tourTodayTab');
  static final journalTab = GlobalKey(debugLabel: 'tourJournalTab');
  static final calendarTab = GlobalKey(debugLabel: 'tourCalendarTab');
  static final auraFab = GlobalKey(debugLabel: 'tourAuraFab');
  static final settingsIcon = GlobalKey(debugLabel: 'tourSettingsIcon');
  static final checkInCard = GlobalKey(debugLabel: 'tourCheckInCard');
  static final journalActions = GlobalKey(debugLabel: 'tourJournalActions');
}

/// First-run guided tour — bottom nav, Aura, Insights' check-in card,
/// Journal's photo/voice/tag row, and the Settings gear. Kept short on
/// purpose: one tight sentence per step, only the handful of things
/// someone actually needs to find on day one.
///
/// Built on showcaseview's v5 API, which (unlike the widely-documented
/// older versions) has no `ShowCaseWidget` tree wrapper — it's a global
/// singleton instead: [register] once, then `ShowcaseView.get()` anywhere
/// to start/advance a sequence.
class AppTour {
  AppTour._();

  static bool _registered = false;

  /// Registers the global showcase manager — safe to call more than
  /// once (a no-op after the first time), so callers don't need to
  /// track this themselves. `skipIfTargetNotPresent` is a defensive
  /// fallback only — [start]'s own `includeCheckIn` param is what
  /// actually decides whether the check-in-card step is attempted at
  /// all, since that widget hides itself outright once today already
  /// has an entry logged.
  static void register() {
    if (_registered) return;
    _registered = true;
    ShowcaseView.register(skipIfTargetNotPresent: true);
  }

  /// Runs the whole tour: bottom nav + Aura + Settings first (all
  /// visible regardless of which tab is active, so no tab switch
  /// needed), then Insights' check-in card, then Journal's photo/voice/
  /// tag row — switching tabs (via [goToTab]) between those last two
  /// segments and giving each a moment to actually lay out before
  /// pointing at it.
  ///
  /// [includeCheckIn] should be false when today already has an entry
  /// logged — the check-in card hides itself in that case (see
  /// InsightsScreen's `_QuickCheckInCard`), so that step is skipped
  /// entirely rather than pointing at nothing.
  static Future<void> start(
    BuildContext context, {
    required Future<void> Function(int tabIndex) goToTab,
    required bool includeCheckIn,
  }) {
    register();
    final showcase = ShowcaseView.get();
    final completer = Completer<void>();

    const settleDelay = Duration(milliseconds: 150);
    final navAndChrome = [
      TourKeys.insightsTab,
      TourKeys.todayTab,
      TourKeys.journalTab,
      TourKeys.calendarTab,
      TourKeys.auraFab,
      TourKeys.settingsIcon,
    ];

    // showcaseview's onComplete fires after *every* step across the
    // whole app finishes, not just this tour's own — so this only acts
    // on the specific keys it's currently waiting on, and unregisters
    // itself once the tour is actually done.
    late final OnShowcaseCallback handler;
    handler = (index, key) {
      if (key == TourKeys.settingsIcon) {
        // First segment done — either the check-in card (switching to
        // Insights first) or straight to Journal's actions row.
        if (includeCheckIn) {
          goToTab(0).then((_) => showcase.startShowCase([TourKeys.checkInCard], delay: settleDelay));
        } else {
          goToTab(2).then((_) => showcase.startShowCase([TourKeys.journalActions], delay: settleDelay));
        }
      } else if (key == TourKeys.checkInCard) {
        goToTab(2).then((_) => showcase.startShowCase([TourKeys.journalActions], delay: settleDelay));
      } else if (key == TourKeys.journalActions) {
        showcase.removeOnCompleteCallback(handler);
        if (!completer.isCompleted) completer.complete();
      }
    };
    showcase.addOnCompleteCallback(handler);

    showcase.startShowCase(navAndChrome, delay: settleDelay);
    return completer.future;
  }

  static String insightsTabText(BuildContext context) => AppLocalizations.of(context)!.tourInsightsTab;
  static String todayTabText(BuildContext context) => AppLocalizations.of(context)!.tourTodayTab;
  static String journalTabText(BuildContext context) => AppLocalizations.of(context)!.tourJournalTab;
  static String calendarTabText(BuildContext context) => AppLocalizations.of(context)!.tourCalendarTab;
  static String auraFabText(BuildContext context) => AppLocalizations.of(context)!.tourAuraFab;
  static String checkInCardText(BuildContext context) => AppLocalizations.of(context)!.tourCheckInCard;
  static String journalActionsText(BuildContext context) => AppLocalizations.of(context)!.tourJournalActions;
  static String settingsIconText(BuildContext context) => AppLocalizations.of(context)!.tourSettingsIcon;
}
