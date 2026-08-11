import 'package:flutter/material.dart';
import 'data/app_state.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LuminaApp());
}

class LuminaApp extends StatefulWidget {
  const LuminaApp({super.key});

  @override
  State<LuminaApp> createState() => _LuminaAppState();
}

class _LuminaAppState extends State<LuminaApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Lumina',
            debugShowCheckedModeBanner: false,
            themeMode: _appState.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
