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

  static const _tabs = [
    TodayScreen(),
    JournalScreen(),
    CalendarScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return Scaffold(
      appBar: const LuminaTopBar(),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _tabs),
          if (appState.auraEnabled) const AuraFab(),
        ],
      ),
      bottomNavigationBar: LuminaBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
