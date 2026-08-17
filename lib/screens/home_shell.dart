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
  void initState() {
    super.initState();
    // Must happen synchronously here, before the first build() — every
    // Showcase-wrapped widget below (bottom nav, Aura FAB, the Settings
    // icon, ...) is unconditionally part of this tree regardless of
    // whether a tour is actually running, and throws immediately at
    // build time if no ShowcaseView is registered yet. Deferring this to
    // a post-frame callback (i.e. only inside _maybeStartTour) was too
    // late — this widget's very first build() already needs it.
    AppTour.register();
  }

  /// Switches tabs (a no-op if already on [index]) and waits a frame so
  /// whatever's newly visible has actually laid out — [AppTour] passes
  /// this in as its own tab-switching hook, since only HomeShell owns
  /// [_index].
  Future<void> _goToTab(int index) async {
    if (!mounted) return;
    if (_index != index) {
      setState(() => _index = index);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Auto-starts the guided tour the first time a signed-in account ever
  /// reaches HomeShell (see [AppState.hasSeenTour]), or any time Settings'
  /// "Take a Tour" row sets [AppState.requestTourReplay] and pops back
  /// here. Checked on every build — cheap when idle (both signals are
  /// just field reads/a no-op consuming getter) and self-guarding via
  /// [_tourRunning] against re-entering mid-tour, the same pattern this
  /// class already uses for the pending-check-in tab switch below.
  void _maybeStartTour(AppState appState) {
    if (_tourRunning) return;
    final replayRequested = appState.takeTourReplayRequested();
    if (!replayRequested && appState.hasSeenTour) return;
    _tourRunning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final includeCheckIn = appState.entriesOn(DateTime.now()).isEmpty;
      await AppTour.start(context, goToTab: _goToTab, includeCheckIn: includeCheckIn);
      appState.dismissTour();
      _tourRunning = false;
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
