import 'package:flutter/material.dart';
import '../data/app_state.dart';
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
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _journalIndex = 2;

  static const _tabs = [
    InsightsScreen(),
    TodayScreen(),
    JournalScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    // A Today check-in was just staged for Journal (see
    // AppState.handOffCheckInToJournal) — switch to that tab so the user
    // lands there to actually compose/save it. JournalScreen itself picks
    // the staged check-in up (and clears the handoff) via
    // didChangeDependencies, independent of this switch.
    if (appState.pendingCheckIn != null && _index != _journalIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = _journalIndex);
      });
    }

    return Scaffold(
      appBar: const LuminaTopBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              IndexedStack(index: _index, children: _tabs),
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
