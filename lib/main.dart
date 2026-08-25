import 'dart:async';

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
import 'services/device_language.dart';
import 'services/notification_service.dart';
import 'services/screenshot_guard.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Awaited before runApp (not left to resolve later, e.g. via a
  // FutureBuilder) so it's already available for LuminaApp's very first
  // build — see DeviceLanguage's own doc for why this needs to exist
  // independently of AppState at all.
  await DeviceLanguage.load();
  ScreenshotGuard.ensureInitialized();
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
        // DeviceLanguage.current, not AppState.languageCode — there's no
        // signed-in AppState at all yet on either branch below, but a
        // language explicitly chosen while signed in (on this device,
        // ever) should still apply here rather than silently falling
        // back to the device's raw system locale the moment someone
        // signs out. Null (nothing ever chosen) leaves `locale` unset,
        // which is exactly the previous system-locale-only behavior.
        final deviceLocale = DeviceLanguage.current == null ? null : Locale(DeviceLanguage.current!);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: deviceLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return MaterialApp(
            title: 'Moodlet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: deviceLocale,
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

  // Lets didChangeAppLifecycleState below pop back to `home` from
  // wherever the Navigator's stack currently is (Settings, an entry, ...)
  // when re-locking — see that method's own doc for why that pop is
  // necessary, not just a nicety.
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Pessimistic default (locked) until the real check resolves, so there's
  // never a frame where real content is reachable before we actually know
  // whether a lock is supposed to be guarding it.
  bool _locked = true;
  bool _lockChecked = false;
  AppLifecycleState? _lastLifecycleState;

  // Debounces didChangeAppLifecycleState's own relock below — see that
  // method's doc for why a brief, cancellable delay (rather than locking
  // the instant focus is lost) is what tells a screenshot's momentary
  // interruption apart from an actual app switch.
  Timer? _relockTimer;

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
    _relockTimer?.cancel();
    _appState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Triggered by *leaving* the foreground, not by coming back to it —
    // AppLockScreen only ever replaces `home`'s own content (see build()
    // below), so if some other screen (Settings, Pattern Lock setup, an
    // entry, ...) was pushed on top of it, that pushed screen just kept
    // covering the swap and the lock never became visible at all — a
    // real, reported bug, not just a cosmetic one. Popping back to `home`
    // here, while the app is backgrounded and nothing is visibly on
    // screen either way, means by the time AppLifecycleState.resumed
    // actually fires, the stack is already back at `home` and _locked is
    // already true — so there's no visible snap from Settings back to
    // Home, and no frame where whatever was pushed shows in front of a
    // lock that's supposed to be blocking it.
    final leavingForeground =
        (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        _lastLifecycleState != AppLifecycleState.paused &&
        _lastLifecycleState != AppLifecycleState.inactive;
    // Not consumed here — see ExternalActivityGuard's own doc for why an
    // operation that's still in flight (the camera, share sheet, a
    // browser link, a permission dialog, ...) needs to keep reading as
    // "expected" for as long as it's actually running, not just for the
    // first leaving-foreground transition it happens to produce.
    final expected = leavingForeground && ExternalActivityGuard.isActive;
    if (leavingForeground && !expected) {
      // Not an immediate relock — a screenshot's own capture UI (notably
      // Samsung's own Smart Capture toolbar, which pops up the instant a
      // screenshot is taken and can stay interactable for a couple of
      // seconds afterward) briefly steals focus the exact same way
      // switching away to another app does, producing this same paused/
      // inactive transition. Waiting a beat and then checking whether the
      // app is *still* not back in the foreground — and still not covered
      // by an ExternalActivityGuard that only started being active after
      // this transition was first seen — is what tells that apart from an
      // actual app switch, which stays backgrounded far longer than this
      // delay either way. ScreenshotGuard's own native signal (Android
      // 14+) is the precise way to catch this, but Samsung's own
      // screenshot pipeline doesn't reliably route through the AOSP hook
      // that signal depends on, so this timing fallback is the one
      // actually carrying the fix on a Samsung device — 2.5s comfortably
      // outlasts that toolbar without meaningfully weakening the lock: a
      // genuine backgrounding still relocks well before anyone could
      // realistically pick the phone back up and return to it.
      _relockTimer?.cancel();
      _relockTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!mounted || _lastLifecycleState == AppLifecycleState.resumed) return;
        if (ExternalActivityGuard.isActive) return;
        _lockService.isLockEnabled().then((enabled) {
          if (!mounted || !enabled) return;
          _navigatorKey.currentState?.popUntil((route) => route.isFirst);
          setState(() => _locked = true);
        });
      });
    } else if (state == AppLifecycleState.resumed) {
      // Back in the foreground before the debounce above ever fired —
      // cancel it so a screenshot's brief interruption never reaches the
      // relock at all.
      _relockTimer?.cancel();
      _relockTimer = null;
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
        navigatorKey: _navigatorKey,
        title: 'Moodlet',
        debugShowCheckedModeBanner: false,
        // Static fallback for the single frame before MaterialApp.builder
        // below first runs; that builder immediately overrides it via a
        // Theme wrapper once AppStateScope is reachable.
        theme: AppTheme.light,
        // DeviceLanguage.current, not appState.languageCode — this
        // MaterialApp (and therefore _LoadingScreen, shown via the
        // FutureBuilder below) builds *before* _appState.ready resolves,
        // while languageCode is still unset regardless of what the
        // account's own actual preference turns out to be — so without
        // this, the loading screen briefly showed in the device's raw
        // system locale even for someone who'd explicitly chosen
        // Chinese. builder's own override below still takes over with
        // the real appState.languageCode once it's actually loaded.
        locale: DeviceLanguage.current == null ? null : Locale(DeviceLanguage.current!),
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
            // Gated on _lockChecked alone here — a quick local prefs
            // read (AppLockService.isLockEnabled) — not on
            // AppState.ready below, which can mean a real network round
            // trip to Firestore. Pattern Lock is a device-local setting
            // (see AppLockService's own doc), unrelated to that cloud
            // data and not gating anything the lock screen itself
            // actually needs, so there was never a good reason to make
            // it wait behind a loading screen before someone could even
            // try entering their pattern.
            if (!_lockChecked) {
              return const _LoadingScreen();
            }
            // Fingerprint Unlock / Pattern Lock gate — shown in front of
            // the real app instead of it, both at cold start and again
            // after returning from the background (didChangeAppLifecycleState
            // above). Its own onUnlocked callback is the only way past it.
            if (_locked) {
              return AppLockScreen(uid: widget.user.uid, onUnlocked: () => setState(() => _locked = false));
            }
            // Only *after* a successful unlock (or when there was never a
            // lock to begin with) does this wait on the actual data
            // restore — the loading screen belongs after Pattern Lock,
            // not in front of it.
            if (snapshot.connectionState != ConnectionState.done) {
              return const _LoadingScreen();
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
            Text(AppLocalizations.of(context)!.loadingPreparingJournal,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
