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
  // Fallback target for the Aura step when Aura is toggled off — the
  // floating chat button hides itself entirely in that case (see
  // AuraFab's own `enabled` handling), so highlighting it would point at
  // nothing visible. This is the top bar's own Aura on/off icon instead,
  // which is always there regardless of the toggle's current state.
  static final auraToggleIcon = GlobalKey(debugLabel: 'tourAuraToggleIcon');
  static final settingsIcon = GlobalKey(debugLabel: 'tourSettingsIcon');

  /// Human-readable name for whatever key a showcaseview callback handed
  /// back — every debugPrint below uses this instead of the raw
  /// GlobalKey (which prints as a mostly-useless hash) so the console
  /// output is actually legible.
  static String nameOf(GlobalKey? key) {
    if (key == insightsTab) return 'insightsTab';
    if (key == todayTab) return 'todayTab';
    if (key == journalTab) return 'journalTab';
    if (key == calendarTab) return 'calendarTab';
    if (key == auraFab) return 'auraFab';
    if (key == auraToggleIcon) return 'auraToggleIcon';
    if (key == settingsIcon) return 'settingsIcon';
    return key?.toString() ?? 'null';
  }
}

/// First-run guided tour — bottom nav, Aura, and the Settings gear. Kept
/// short on purpose: one tight sentence per step, only the handful of
/// things someone actually needs to find on day one. (Used to also stop
/// at Insights' check-in card and Journal's photo/voice/tag row, both
/// dropped — everything they demonstrate is also reachable from tabs
/// already covered by an earlier step, and cutting them means the tour
/// never needs to switch tabs at all.)
///
/// Built on showcaseview's v5 API, which (unlike the widely-documented
/// older versions) has no `ShowCaseWidget` tree wrapper — it's a global
/// singleton instead: [register] once, then `ShowcaseView.get()` anywhere
/// to start/advance a sequence.
///
/// Every step below logs via debugPrint (visible in `flutter run`'s
/// terminal, or the browser console on web) — this feature has gone
/// through several rounds of "compiles clean, still doesn't work at
/// runtime" with no visibility into *where* it's actually getting stuck,
/// so logging every decision point beats guessing at another fix blind.
class AppTour {
  AppTour._();

  // MUST be called exactly once per app session, no exceptions — proven
  // the hard way, three separate times, by three different attempts to
  // relax this (a locale-gated re-register, a force:true re-register
  // confined to right before each tour attempt, and — the one that
  // seemed safest on paper — a lazily-resolving Builder-based button
  // that never should have needed a second registration at all). Every
  // one of them broke the tour outright, not just the translation it was
  // trying to fix. Whatever ShowcaseView.register() does internally,
  // calling it again — for any reason, on any schedule — appears to
  // orphan every already-mounted Showcase widget's target registration.
  static bool _registered = false;

  /// HomeShell's current BuildContext, refreshed on *every*
  /// didChangeDependencies firing (see [updateContext]) — unlike
  /// [register] itself, updating this has nothing to do with
  /// ShowcaseView's own registration and is always safe to do as often
  /// as needed. This is what [_TourActionButton] actually reads
  /// AppLocalizations from, instead of either a string frozen at
  /// registration time (stale after a language switch) or the button's
  /// own BuildContext (which sits inside showcaseview's overlay —
  /// apparently outside this app's Localizations.override scope, since
  /// a Builder reading its own context tried this already and still
  /// showed the wrong language). A context HomeShell itself is holding
  /// onto is guaranteed to be inside that scope, and current, since the
  /// tour only ever runs while HomeShell is mounted and on screen.
  static BuildContext? _currentContext;

  /// Called unconditionally from HomeShell's didChangeDependencies —
  /// deliberately separate from [register] so keeping this fresh never
  /// touches ShowcaseView's own registration.
  static void updateContext(BuildContext context) => _currentContext = context;

  /// Whichever step's key the tour is currently showing — updated by
  /// register()'s own onStart callback below, watched by
  /// _TourActionButton (via ValueListenableBuilder) to decide its
  /// label/visibility for the current step. A ValueNotifier specifically,
  /// not a bare static field — a bare field has no way to tell Flutter a
  /// rebuild is needed when it changes, so _TourActionButton's build()
  /// would only happen to pick up the new value whenever showcaseview's
  /// own internals happened to rebuild that widget for some *other*
  /// reason (e.g. the step's description text changing) — true often
  /// enough to look like it worked in casual testing, but not guaranteed,
  /// and the actual reported failure (the barrier left stuck open after
  /// tapping what should have been the tour's very last "Got it") is
  /// exactly what a missed rebuild looks like. A ValueNotifier's own
  /// listener mechanism doesn't depend on any of that — it fires whether
  /// or not anything else nearby happens to rebuild at the same time.
  static final ValueNotifier<GlobalKey?> _activeKey = ValueNotifier(null);

  /// Registers the global showcase manager — a genuine no-op after the
  /// first successful call (see [_registered] above), so callers don't
  /// need to track that themselves.
  static void register(BuildContext context) {
    if (_registered) return;
    _registered = true;
    debugPrint('[AppTour] register() called (first and only time this session)');
    ShowcaseView.register(
      // A tap on the highlighted target used to also reach the real
      // widget underneath — tapping the highlighted "Journal" tab
      // during the tour both advanced the tour *and* actually
      // navigated there for real, same for "Add Photo" opening a real
      // camera/gallery sheet mid-tour. Disabling barrier interaction
      // means only the tooltip's own Next/Skip controls advance or end
      // the tour — the target itself stops being clickable through it.
      disableBarrierInteraction: true,
      skipIfTargetNotPresent: true,
      // An explicit Next button is required here, not just nice to have
      // — disableBarrierInteraction above turns off tap-anywhere-to-
      // advance (that's what let a tap reach the real widget underneath
      // in the first place), and without something else to replace it,
      // the tour silently gets stuck on step one forever: Skip ends the
      // whole sequence, it doesn't step forward. .custom() (not a plain
      // TooltipActionButton(name: ...)) so the label can be resolved
      // from [_currentContext] — see that field's own doc for why.
      //
      // Both buttons stay the exact same globally-registered instances
      // for every single step, Settings (the last one) included — a
      // per-step Showcase.tooltipActions override was tried instead (so
      // the last step could show a single "Got it" rather than this
      // Next/Skip pair) and left the dimmed barrier stuck on screen after
      // tapping it, never actually tearing down. _TourActionButton's own
      // build() now watches [_activeKey] (a ValueNotifier — see its own
      // doc for why not a bare field) to change its label/visibility
      // instead — the underlying next()/dismiss() calls below are
      // untouched, so whatever showcaseview needs internally to clean up
      // properly is unaffected by which step is currently showing.
      globalTooltipActions: [
        TooltipActionButton.custom(
          button: _TourActionButton(
            onTap: () => ShowcaseView.get().next(),
            label: (l10n, activeKey) => activeKey == TourKeys.settingsIcon ? l10n.tourDone : l10n.tourNext,
          ),
        ),
        TooltipActionButton.custom(
          button: _TourActionButton(
            onTap: () => ShowcaseView.get().dismiss(),
            label: (l10n, activeKey) => l10n.tourSkip,
            // Settings is the tour's last step — hidden there since
            // tapping Next/"Got it" already ends the tour by itself
            // (there's nothing left to skip *to*), leaving a single
            // visible button instead of two that do the same thing.
            visible: (activeKey) => activeKey != TourKeys.settingsIcon,
          ),
        ),
      ],
      onStart: (index, key) {
        _activeKey.value = key;
        debugPrint('[AppTour] showcase onStart: index=$index key=${TourKeys.nameOf(key)}');
      },
    );
  }

  /// Runs the whole tour: bottom nav + Aura + Settings — all visible
  /// regardless of which tab is active, so no tab switch is ever needed.
  /// Resolves whether the tour ran to completion or was cut short via
  /// the Skip button — either way counts as "seen".
  ///
  /// [auraEnabled] should match AppState.auraEnabled — when false, the
  /// floating Aura button hides itself entirely (see AuraFab's own
  /// `enabled` handling), so this points the Aura step at the top bar's
  /// own Aura on/off icon instead, which is always visible regardless of
  /// that toggle.
  static Future<void> start(
    BuildContext context, {
    required bool auraEnabled,
  }) {
    debugPrint('[AppTour] start() called — auraEnabled=$auraEnabled');
    // Deliberately NOT calling register() again here, under any
    // condition — see _registered's doc for the three separate ways
    // that was tried and broke the tour every time. HomeShell's
    // didChangeDependencies already guarantees registration happened
    // before this is ever reachable.
    final showcase = ShowcaseView.get();
    // Defensive: force-clear any state left over from a previous run —
    // the pattern reported ("works the very first time, flaky or stuck
    // on any later attempt") looks exactly like the singleton's own
    // internal "currently showing" bookkeeping not having been reset
    // cleanly (a prior run that got interrupted by a hot reload rather
    // than a full page reload, for instance). A no-op if nothing is
    // currently active — safe to call unconditionally before every run.
    debugPrint('[AppTour] calling dismiss() defensively before starting, to clear any leftover state');
    showcase.dismiss();
    final completer = Completer<void>();

    const settleDelay = Duration(milliseconds: 150);
    final navAndChrome = [
      TourKeys.insightsTab,
      TourKeys.todayTab,
      TourKeys.journalTab,
      TourKeys.calendarTab,
      auraEnabled ? TourKeys.auraFab : TourKeys.auraToggleIcon,
      TourKeys.settingsIcon,
    ];

    // showcaseview's onComplete/onDismiss fire for *every* showcase
    // across the whole app, not just this tour's own — these only act
    // on the specific keys/moments they're currently waiting on, and
    // unregister themselves once the tour is actually over (however it
    // ended), rather than lingering and reacting to some unrelated
    // later showcase.
    late final OnShowcaseCallback onComplete;
    late final OnDismissCallback onDismiss;
    void finish(String reason) {
      debugPrint('[AppTour] finish() — $reason');
      // Deferred via scheduleMicrotask, not called synchronously here —
      // this is the actual root cause of the dimmed barrier being left
      // stuck open at the end of every tour run, regardless of which
      // button ended it. removeOnCompleteCallback/removeOnDismissCallback
      // both do a plain List.remove() on the exact list showcaseview is
      // *mid-iteration* over right now: both onComplete and onDismiss are
      // invoked from inside a `for (final callback in ...)` loop over
      // that same list (see ShowcaseView's own _onComplete/dismiss), and
      // finish() (called from *inside* those callbacks) used to remove
      // itself from that list on the spot. Mutating a List while
      // iterating it is a textbook ConcurrentModificationError in Dart —
      // the thrown exception broke the Future chain
      // _changeSequence/dismiss rely on to ever reach the code that
      // actually tears the overlay down, so it silently never happened.
      // Scheduling this for the next microtask lets the current
      // iteration finish untouched first.
      scheduleMicrotask(() {
        showcase.removeOnCompleteCallback(onComplete);
        showcase.removeOnDismissCallback(onDismiss);
      });
      if (!completer.isCompleted) completer.complete();
    }

    onComplete = (index, key) {
      debugPrint('[AppTour] onComplete fired — index=$index key=${TourKeys.nameOf(key)}');
      if (key == TourKeys.settingsIcon) {
        finish('settingsIcon completed — natural end of tour');
      } else {
        debugPrint('[AppTour] onComplete for a mid-sequence key (${TourKeys.nameOf(key)}) — nothing to do, '
            'showcaseview advances to the next key in the same startShowCase list on its own');
      }
    };
    // Skip ends the whole sequence early (see TooltipDefaultActionType.
    // skip's built-in behavior) — this still counts as the tour having
    // been "seen", same as reaching the natural last step.
    onDismiss = (dismissedAt) {
      debugPrint('[AppTour] onDismiss fired — dismissedAt=${TourKeys.nameOf(dismissedAt)}');
      finish('dismissed (Skip tapped, or barrier/back dismissed it)');
    };

    showcase.addOnCompleteCallback(onComplete);
    showcase.addOnDismissCallback(onDismiss);

    debugPrint('[AppTour] calling startShowCase for: '
        '${navAndChrome.map(TourKeys.nameOf).join(', ')}');
    showcase.startShowCase(navAndChrome, delay: settleDelay);
    // A hard ceiling on the whole tour, not just a nicety — this is
    // exactly what the double-registration bug exposed: when nothing
    // ever calls onComplete/onDismiss, this Future (and therefore
    // HomeShell's own `await AppTour.start(...)`) would otherwise just
    // hang forever, permanently stuck with _tourRunning still true and
    // silently blocking every future tour attempt for the rest of the
    // session, with no error and nothing on screen to explain why. Now
    // it gives up on its own instead of relying on every possible
    // failure mode inside showcaseview to correctly fire one of the two
    // callbacks above.
    return completer.future.timeout(const Duration(seconds: 20), onTimeout: () {
      debugPrint('[AppTour] TIMED OUT after 20s waiting for the tour to finish or be dismissed — '
          'giving up so this session isn\'t left permanently stuck');
      finish('timed out');
    });
  }

  static String insightsTabText(BuildContext context) => AppLocalizations.of(context)!.tourInsightsTab;
  static String todayTabText(BuildContext context) => AppLocalizations.of(context)!.tourTodayTab;
  static String journalTabText(BuildContext context) => AppLocalizations.of(context)!.tourJournalTab;
  static String calendarTabText(BuildContext context) => AppLocalizations.of(context)!.tourCalendarTab;
  static String auraFabText(BuildContext context) => AppLocalizations.of(context)!.tourAuraFab;
  static String auraToggleText(BuildContext context) => AppLocalizations.of(context)!.tourAuraToggle;
  static String settingsIconText(BuildContext context) => AppLocalizations.of(context)!.tourSettingsIcon;
}

/// One of the tour's own Next/Skip pills. Reads its label from
/// [AppTour._currentContext] — HomeShell's own, always-current
/// BuildContext — rather than the BuildContext this widget itself
/// builds with (that one sits inside showcaseview's overlay, which
/// isn't inside this app's Localizations.override scope, so
/// AppLocalizations.of(context) here directly resolved the wrong
/// language even though this widget rebuilds fresh every time it
/// paints — this isn't a staleness problem, it's a wrong-ancestor one).
class _TourActionButton extends StatelessWidget {
  const _TourActionButton({required this.onTap, required this.label, this.visible = _alwaysVisible});

  final VoidCallback onTap;
  final String Function(AppLocalizations l10n, GlobalKey? activeKey) label;
  // A function, not a plain bool — evaluated fresh on every rebuild
  // ValueListenableBuilder below triggers (i.e. every AppTour._activeKey
  // change), same as [label].
  final bool Function(GlobalKey? activeKey) visible;

  static bool _alwaysVisible(GlobalKey? activeKey) => true;

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder, not a bare read of AppTour._activeKey.value
    // — see that field's own doc for why a plain read here wouldn't
    // reliably trigger a rebuild when it changes. This subscribes
    // directly, independent of whatever showcaseview's own internals do
    // or don't rebuild around it.
    return ValueListenableBuilder<GlobalKey?>(
      valueListenable: AppTour._activeKey,
      builder: (context, activeKey, _) {
        if (!visible(activeKey)) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final goodContext = AppTour._currentContext;
        final text = goodContext == null ? '' : label(AppLocalizations.of(goodContext)!, activeKey);
        return Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              child: Text(
                text,
                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        );
      },
    );
  }
}
