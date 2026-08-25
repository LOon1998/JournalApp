import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../services/app_tour.dart';
import '../widgets/aura_fab.dart';
import '../widgets/lumina_bottom_nav.dart';
import '../widgets/lumina_top_bar.dart';
import 'calendar_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';
import 'today_screen.dart';

/// Hosts the four bottom-nav tabs plus the persistent Aura FAB, matching
/// the shared header/footer chrome across every mockup screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  /// Which tab to land on first — defaults to Insights (index 0), the
  /// normal cold-start tab. WelcomeScreen's "Start My First Check-in"
  /// passes [todayTabIndex] instead, so a brand-new account lands
  /// somewhere that actually matches that button's promise.
  final int initialIndex;

  /// Public so callers outside this file (WelcomeScreen) can target the
  /// Today tab without hardcoding its position in the bottom nav.
  static const todayTabIndex = 1;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  static const _insightsIndex = 0;
  static const _journalIndex = 2;
  static const _calendarIndex = 3;

  // Guards against starting a second tour while one's already running —
  // e.g. the tour's own tab switches trigger rebuilds, which would
  // otherwise re-enter _maybeStartTour on every one of them.
  bool _tourRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not initState — AppTour.register reads AppLocalizations.of(context)
    // (just to size the Skip button's label), and establishing a *new*
    // inherited-widget dependency from initState is a hard Flutter
    // assertion failure ("dependOnInheritedWidgetOfExactType... called
    // before initState() completed"), not just a style nit.
    // didChangeDependencies still runs before this widget's first
    // build() (same guarantee initState would have given), which is what
    // actually matters here — every Showcase-wrapped widget below
    // (bottom nav, Aura FAB, the Settings icon, ...) is unconditionally
    // part of this tree regardless of whether a tour is running, and
    // throws immediately at build time if no ShowcaseView is registered
    // yet. Cheap and safe to call every time this fires (e.g. on a
    // locale change) — see AppTour.register's own doc.
    AppTour.register(context);
    // Unconditional (unlike register above) — this is what keeps the
    // tour's Next/Skip button labels correctly translated even long
    // after registration itself happened; see AppTour._currentContext's
    // own doc for why this had to be a separate, always-safe-to-repeat
    // update rather than folded into register().
    AppTour.updateContext(context);
  }

  /// Auto-starts the guided tour the first time a signed-in account ever
  /// reaches HomeShell (see [AppState.hasSeenTour]), or any time Settings'
  /// "Take a Tour" row sets [AppState.requestTourReplay] and pops back
  /// here. Checked on every build — cheap when idle (both signals are
  /// just field reads/a no-op consuming getter) and self-guarding via
  /// [_tourRunning] against re-entering mid-tour, the same pattern this
  /// class already uses for the pending-check-in tab switch below.
  void _maybeStartTour(AppState appState) {
    if (_tourRunning) {
      debugPrint('[HomeShell] _maybeStartTour: skipped — a tour is already running (_tourRunning=true)');
      return;
    }
    final replayRequested = appState.takeTourReplayRequested();
    if (!replayRequested && appState.hasSeenTour) {
      debugPrint('[HomeShell] _maybeStartTour: skipped — replayRequested=false and hasSeenTour=true '
          '(nothing asked for a replay, and it already auto-played once before)');
      return;
    }
    debugPrint('[HomeShell] _maybeStartTour: starting — replayRequested=$replayRequested '
        'hasSeenTour=${appState.hasSeenTour}');
    _tourRunning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        debugPrint('[HomeShell] _maybeStartTour: post-frame callback ran but widget is unmounted — bailing');
        return;
      }
      try {
        debugPrint('[HomeShell] _maybeStartTour: calling AppTour.start '
            '(auraEnabled=${appState.auraEnabled})');
        await AppTour.start(
          context,
          auraEnabled: appState.auraEnabled,
        );
        debugPrint('[HomeShell] _maybeStartTour: AppTour.start returned — calling dismissTour()');
        appState.dismissTour();
      } catch (e, st) {
        debugPrint('[HomeShell] _maybeStartTour: AppTour.start THREW: $e\n$st');
      } finally {
        // Unconditionally, even if AppTour.start threw — otherwise a
        // single failed run (a bad target, a mid-tour exception) leaves
        // this stuck true forever, silently no-oping every future tour
        // attempt (auto-start *and* Settings' "Take a Tour") for the
        // rest of the session, with nothing on screen to explain why.
        _tourRunning = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    _maybeStartTour(appState);

    // Rebuilt (not a static const list) so InsightsScreen/JournalScreen/
    // CalendarScreen can be told whether they're the tab currently
    // showing — see their `active` fields. IndexedStack still keys these
    // by position/type, so this doesn't lose any of their State when
    // _index changes.
    final tabs = [
      InsightsScreen(active: _index == _insightsIndex),
      const TodayScreen(),
      JournalScreen(active: _index == _journalIndex),
      CalendarScreen(active: _index == _calendarIndex),
    ];

    // A Today check-in was just staged for Journal (see
    // AppState.handOffCheckInToJournal) — switch to that tab so the user
    // lands there to actually compose/save it. JournalScreen itself picks
    // the staged check-in up (and clears the handoff) via
    // didChangeDependencies, independent of this switch. Same deal for a
    // "Save Mood Only" quick entry (AppState.addQuickEntry) — Journal
    // consumes justAddedEntryId to scroll to and briefly highlight it.
    final needsJournalTab = appState.pendingCheckIn != null || appState.justAddedEntryId != null;
    if (needsJournalTab && _index != _journalIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = _journalIndex);
      });
    }

    return Scaffold(
      // Insights skips the avatar (and left-aligns the logo instead of
      // centering it) — it already opens with its own "Welcome back"
      // card showing the same photo right below, so repeating it here
      // too was a redundant second avatar. Every other tab keeps both.
      appBar: LuminaTopBar(showAvatar: _index != _insightsIndex),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              IndexedStack(index: _index, children: tabs),
              // Always present (never `if (auraEnabled) ...`) so its State
              // — and therefore its dragged-to position — survives being
              // toggled off instead of resetting every time it's shown
              // again. `enabled` controls visibility/interactivity inside
              // AuraFab itself; Positioned must stay a direct child of
              // Stack, so nothing (e.g. Offstage) can wrap it here.
              AuraFab(bounds: constraints.biggest, enabled: appState.auraEnabled),
            ],
          );
        },
      ),
      bottomNavigationBar: LuminaBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
