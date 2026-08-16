import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'data/app_state.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/app_lock_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/app_lock_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LuminaApp());
}

/// Decides, at the top level, whether there's a signed-in Firebase user —
/// each branch below builds its own complete [MaterialApp] (own Navigator,
/// own Overlay) rather than sharing one. That matters: [AppStateScope]
/// needs to wrap *every* route that can ever be pushed (Settings, entry
/// detail, Aura chat, ...), not just whichever widget happens to be
/// `home`. Nesting the auth gate *inside* a single shared MaterialApp's
/// `home` — the first version of this — put AppStateScope inside that one
/// initial route's own subtree, so any screen reached via
/// `Navigator.push` (a sibling route in the same Navigator, not a
/// descendant of `home`) couldn't see it and crashed with "No
/// AppStateScope found in context." Building a fresh MaterialApp per
/// branch instead means AppStateScope sits above that branch's entire
/// Navigator, so it's visible from every route pushed onto it — and
/// signing out cleanly discards the whole Navigator/Overlay along with
/// it, rather than leaving stale pushed routes behind.
class LuminaApp extends StatelessWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          // No AppState (and therefore no saved language preference) exists
          // yet pre-sign-in — falls back to whatever locale the device
          // itself is set to, same as leaving `locale:` unset always does.
          return MaterialApp(
            title: 'Moodlet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthScreen(),
          );
        }
        // Keyed by uid so switching accounts on the same device tears down
        // the old _SignedInApp (and the AppState/uid-scoped cache inside
        // it) and mounts a completely fresh one, rather than reusing state
        // that belongs to whoever was signed in before.
        return _SignedInApp(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.user});

  final User user;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> with WidgetsBindingObserver {
  late final AppLockService _lockService = AppLockService(widget.user.uid);

  // Pessimistic default (locked) until the real check resolves, so there's
  // never a frame where real content is reachable before we actually know
  // whether a lock is supposed to be guarding it.
  bool _locked = true;
  bool _lockChecked = false;
  AppLifecycleState? _lastLifecycleState;

  late final AppState _appState = AppState(
    uid: widget.user.uid,
    userName: widget.user.displayName?.trim().isNotEmpty == true
        ? widget.user.displayName!.trim()
        : (widget.user.email ?? '').split('@').first,
    userEmail: widget.user.email ?? '',
    // Null for every case except the sign-up that just created this
    // account with a photo picked — see AuthService.consumePendingAvatar.
    profilePhotoBase64: AuthService.consumePendingAvatar(),
  );

  // Read once, right when this account's session starts — true only for
  // the sign-up that just created it, never for a returning sign-in
  // (including this same account's next app launch). See
  // AuthService.consumeJustSignedUp. Kept separately from [_showWelcome]
  // (which flips off once the welcome screen's continue button is
  // tapped) so HomeShell still knows to open on the Today tab afterward.
  final bool _isFreshSignUp = AuthService.consumeJustSignedUp();
  late bool _showWelcome = _isFreshSignUp;

  // Re-applied once per session (not on every FutureBuilder rebuild below
  // — harmless either way, but no reason to repeat it) once AppState.ready
  // resolves. Android can drop a scheduled alarm across a reboot or a
  // force-stop; reasserting it here on every launch that already has the
  // switch on is what keeps a stale/lost schedule from going unnoticed.
  bool _notificationsRescheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  Future<void> _checkLock() async {
    final enabled = await _lockService.isLockEnabled();
    if (!mounted) return;
    setState(() {
      _locked = enabled;
      _lockChecked = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock on the transition back from the background — not on the
    // very first "resumed" callback at cold start, which _checkLock()
    // above already covers on its own.
    if (state == AppLifecycleState.resumed &&
        (_lastLifecycleState == AppLifecycleState.paused || _lastLifecycleState == AppLifecycleState.inactive)) {
      _lockService.isLockEnabled().then((enabled) {
        if (mounted && enabled) setState(() => _locked = true);
      });
    }
    _lastLifecycleState = state;
  }

  @override
  Widget build(BuildContext context) {
    // MaterialApp itself is built exactly once per sign-in session (only
    // this State's own setState — the welcome-screen continue button —
    // ever rebuilds it), so its Navigator/Overlay (and everything pushed
    // onto it: Settings, dialogs, entry detail, ...) is never touched by
    // AppState changes at all. Reacting to AppState (currently just the
    // theme) happens *inside* MaterialApp.builder instead, which wraps
    // only the already-built route content in a fresh Theme — it doesn't
    // reconstruct the Navigator or any route in it. This is deliberately
    // narrower than the previous approach (an AnimatedBuilder, and later
    // a plain AppStateScope.of(context)-reading widget, both *above*
    // MaterialApp) — either of those meant every single AppState change,
    // including ones fired while a dialog was still mid-close-transition,
    // rebuilt the entire app including the Navigator, which surfaced as a
    // string of different-looking but same-root-cause crashes (an
    // InheritedElement assertion, "dirty widget in the wrong build
    // scope", a disposed TextEditingController still bound to an
    // on-screen TextField). Keeping the Navigator itself permanently
    // stable removes that whole class of timing race at the source,
    // rather than continuing to patch each timing symptom individually.
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        title: 'Moodlet',
        debugShowCheckedModeBanner: false,
        // Static fallback for the single frame before MaterialApp.builder
        // below first runs; that builder immediately overrides it via a
        // Theme wrapper once AppStateScope is reachable.
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final appState = AppStateScope.of(context);
          final theme = appState.themeMode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
          // Same reasoning as the Theme wrap right below it: MaterialApp
          // itself is only ever built once per session (see the big
          // comment above), so a language change made in Settings has to
          // take effect by overriding this *subtree's* locale here in
          // builder — not by changing MaterialApp's own `locale` param,
          // which wouldn't actually re-run without MaterialApp itself
          // rebuilding. Null (follow system) just lets it fall through to
          // whatever locale MaterialApp already resolved on its own.
          final languageCode = appState.languageCode;
          final content = Theme(data: theme, child: child!);
          return languageCode == null
              ? content
              : Localizations.override(context: context, locale: Locale(languageCode), child: content);
        },
        // Waits for AppState.ready (the initial restore) before showing
        // the real screen — otherwise this would briefly show whatever
        // defaults the constructor seeded (a stranger's name derived from
        // the email, no photo) before visibly popping over to the actual
        // restored values a moment later. The Navigator itself still
        // never rebuilds for this (see the comment above) — home is only
        // ever built once; FutureBuilder just decides what that one build
        // shows.
        home: FutureBuilder<void>(
          future: _appState.ready,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done || !_lockChecked) {
              return const _LoadingScreen();
            }
            // Fingerprint Unlock / Pattern Lock gate — shown in front of
            // the real app instead of it, both at cold start and again
            // after returning from the background (didChangeAppLifecycleState
            // above). Its own onUnlocked callback is the only way past it.
            if (_locked) {
              return AppLockScreen(uid: widget.user.uid, onUnlocked: () => setState(() => _locked = false));
            }
            if (!_notificationsRescheduled) {
              _notificationsRescheduled = true;
              if (_appState.notificationsEnabled) {
                NotificationService.scheduleDailyReminder();
              }
            }
            return _showWelcome
                ? WelcomeScreen(onContinue: () => setState(() => _showWelcome = false))
                : HomeShell(initialIndex: _isFreshSignUp ? HomeShell.todayTabIndex : 0);
          },
        ),
      ),
    );
  }
}

/// Shown while [AppState.ready] is still pending — see the FutureBuilder
/// above. The real Moodlet logo mark (assets/branding/logoIcon.png) with
/// a slow breathing pulse, rather than a static placeholder icon, since
/// this is the very first thing anyone sees after signing in.
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen> with SingleTickerProviderStateMixin {
  late final _pulseController =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.05).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Image.asset('assets/branding/logoIcon.png', width: 120, height: 120),
            ),
            const SizedBox(height: 20),
            Text('Preparing your journal...',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
