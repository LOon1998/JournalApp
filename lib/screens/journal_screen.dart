import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/gemini_service.dart';
import '../services/media_capture.dart';
import '../services/text_measure.dart';
import '../theme/activity_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/entries_history_row.dart';
import '../widgets/mini_chip.dart';
import '../widgets/mood_emoji.dart';
import '../widgets/photo_tile.dart';
import '../widgets/theme_swatch.dart';
import '../widgets/voice_note_player.dart';
import '../widgets/voice_recorder_sheet.dart';
import 'deleted_entries_screen.dart';
import 'entry_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.active = true});

  /// Whether this tab is the one currently showing — HomeShell's
  /// IndexedStack keeps every tab's State alive even while hidden, so
  /// this is how JournalScreen finds out it's been switched away from,
  /// to collapse any expanded entry card (see didUpdateWidget below).
  final bool active;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // Generous on purpose (~800-1,000 words) — journaling shouldn't hit a
  // wall mid-thought. This is a safety ceiling against pathological input
  // (e.g. pasting a whole document) more than a real writing limit, since
  // entries are stored as one JSON blob in SharedPreferences.
  static const _maxJournalLength = 5000;

  // Short on purpose — this is a headline shown on entry cards, not a
  // second place to write, so it's capped well below the body text.
  static const _maxTitleLength = 40;

  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  Mood _mood = Mood.good;
  // Only ever set once, here — after that it just carries over from
  // whatever was last picked (see _complete(), which deliberately
  // doesn't reset it), same in light or dark mode.
  String? _themeName = defaultJournalTheme;
  final Set<String> _tags = {};
  final List<String> _photos = [];
  String? _voiceNote;
  final _tagController = TextEditingController();
  bool _showTagField = false;

  static const _tagOptions = ['Family', 'Work', 'Health'];

  // A tag is a short label, not a place to write — long enough for
  // something like "Doctor Visit" (12 chars) without room for someone
  // pasting in a whole sentence as a "tag".
  static const _maxTagLength = 15;

  // Custom ones typed via "+" — separate from the fixed preset options
  // above. Without a cap, this could grow without bound and push the
  // whole composer into an ever-longer scroll.
  static const _maxCustomTags = 8;

  // Today's entries show in pages of up to this many (prev/next + dots
  // between pages) rather than as one long scrolling list, or one entry
  // per page — with the 10/day cap that's 2 pages at most.
  static const _entriesPerPage = 5;

  // null means "not navigated yet", which resolves to the page holding
  // the most recent entry (see build()).
  int? _currentPageIndex;

  // Briefly highlights whichever entry was just created (by "Complete
  // Entry" here, or "Save Mood Only" elsewhere — see AppState.
  // addQuickEntry) so it's obvious exactly where it landed.
  String? _highlightedEntryId;

  // Which entry card (if any) is expanded — lifted up here instead of
  // living in each _TimelineRow's own State, so only one card can be open
  // at a time (expanding one collapses whichever was open before), and so
  // it can be reset to collapsed after returning from viewing/editing any
  // entry (see the onOpened callback passed to _TimelineRow below).
  String? _expandedEntryId;

  // Scroll targets: _carouselKey for "Complete Entry"/"Save Mood Only"
  // (brings today's entries back into view), _reflectionKey for "Save &
  // Write Journal" (jumps straight to the composer).
  final _carouselKey = GlobalKey();
  final _reflectionKey = GlobalKey();

  // Drives "anchor to top" directly instead of via Scrollable.ensureVisible
  // on _carouselKey — that key sits right near the top of the list anyway,
  // so scrolling straight to offset 0 is both simpler and more reliable
  // than depending on the key's render object being laid out/measured
  // correctly by the time the scroll attempt runs.
  final _scrollController = ScrollController();

  // Set the instant a real touch-drag starts on this list (see the
  // NotificationListener wrapping the ListView in build()) — cleared again
  // each time a fresh auto-scroll begins (_scrollTo/_scrollToTop). Every
  // retry loop below checks this before doing anything, so a genuine user
  // scroll always wins immediately instead of being fought: without this,
  // _verifyAndScrollTo/_pollAndScrollToTop's own animateTo being
  // interrupted by a touch-drag still looked, from their perspective, like
  // "not at the target yet" — meaning they'd just try to animate straight
  // back to it, again and again for the rest of their retry budget, which
  // would have felt exactly like the list fighting your own scroll.
  bool _userTookOverScroll = false;

  // Several staggered delays for the follow-up attempts _pollAndScrollTo/
  // _pollAndScrollToTop fire once the poll below lands — the on-screen
  // keyboard's own dismiss animation (outside Flutter's control, and
  // highly device-dependent) can keep resizing the viewport for a while
  // even after this tab is confirmed active, throwing off the very first
  // attempt's math. Each is a cheap no-op if an earlier one already got
  // there.
  static const _scrollRetryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 500),
    Duration(milliseconds: 900),
    Duration(milliseconds: 1500),
  ];

  // Polls once per frame (re-scheduling itself via addPostFrameCallback)
  // until widget.active is confirmed true, then performs the scroll —
  // tied to this screen's own actual, current configuration instead of
  // guessed millisecond delays or trusting a Scrollable.ensureVisible/
  // animateTo Future's completion timing. Both of those turned out
  // unreliable on an actual phone (this tested fine in Chrome on
  // desktop, where frame/animation timing is faster and more
  // predictable): a scroll attempt's Future can complete "successfully"
  // from Flutter's own perspective while this tab is still the
  // *inactive* IndexedStack branch — well before HomeShell's own
  // postFrameCallback flips to it a frame later — which any scheme
  // that trusted that completion to mean "done" would wrongly treat as
  // landed, leaving nothing left to retry once the tab is genuinely
  // visible. widget.active is a plain, present-tense fact about this
  // screen's current configuration, not a promise about some earlier
  // async call, so checking it fresh every frame can't be fooled the
  // same way. 180 frames (~3s at 60fps) is a hard ceiling so a stuck
  // check (this screen navigated away before ever activating, say)
  // doesn't poll forever.
  void _pollAndScrollToTop({int attemptsLeft = 180, bool logged = false}) {
    if (!mounted) return;
    if (attemptsLeft <= 0) {
      debugPrint(
        '[JournalScroll] _pollAndScrollToTop gave up — never saw widget.active become true',
      );
      return;
    }
    if (!widget.active) {
      if (!logged)
        debugPrint(
          '[JournalScroll] _pollAndScrollToTop waiting — widget.active is still false',
        );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) =>
            _pollAndScrollToTop(attemptsLeft: attemptsLeft - 1, logged: true),
      );
      return;
    }
    debugPrint(
      '[JournalScroll] _pollAndScrollToTop: widget.active is now true — attempting',
    );
    FocusScope.of(context).unfocus();
    void attempt() {
      if (_userTookOverScroll) {
        debugPrint(
          '[JournalScroll] scrollToTop attempt skipped — user took over the scroll',
        );
        return;
      }
      if (mounted && _scrollController.hasClients) {
        debugPrint(
          '[JournalScroll] scrollToTop attempt — current offset=${_scrollController.offset}, '
          'maxScrollExtent=${_scrollController.position.maxScrollExtent}',
        );
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } else {
        debugPrint(
          '[JournalScroll] scrollToTop attempt skipped — mounted=$mounted, '
          'hasClients=${_scrollController.hasClients}',
        );
      }
    }

    attempt();
    for (final delay in _scrollRetryDelays) {
      Future.delayed(delay, attempt);
    }
  }

  void _scrollToTop() {
    _userTookOverScroll = false;
    _pollAndScrollToTop();
  }

  // See _pollAndScrollToTop's own doc for the full reasoning.
  void _pollAndScrollTo(
    GlobalKey key, {
    int attemptsLeft = 180,
    bool logged = false,
  }) {
    if (!mounted) return;
    if (attemptsLeft <= 0) {
      debugPrint(
        '[JournalScroll] _pollAndScrollTo gave up — never saw widget.active become true',
      );
      return;
    }
    if (!widget.active) {
      if (!logged)
        debugPrint(
          '[JournalScroll] _pollAndScrollTo waiting — widget.active is still false',
        );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) =>
            _pollAndScrollTo(key, attemptsLeft: attemptsLeft - 1, logged: true),
      );
      return;
    }
    debugPrint(
      '[JournalScroll] _pollAndScrollTo: widget.active is now true — attempting',
    );
    FocusScope.of(context).unfocus();
    _verifyAndScrollTo(key, verifyAttemptsLeft: 25);
  }

  // Keeps retrying — checking the *actual* resulting scroll position
  // after each attempt, not just firing a fixed number of blind guesses
  // and hoping one of them happened to land — until the target genuinely
  // ends up at the top of the viewport (alignment 0, same as
  // Scrollable.ensureVisible used below) or a generous ceiling is hit.
  // This replaced a fixed set of staggered-delay Scrollable.ensureVisible
  // retries that, even combined with polling for widget.active, still
  // wasn't reliably landing in every reported case (specifically: from a
  // scroll position already near the very bottom of this screen's
  // content). Computing the target offset directly via
  // RenderAbstractViewport (the same calculation ensureVisible makes
  // internally) and comparing it to the controller's actual current
  // offset removes any guesswork about whether an earlier attempt
  // "worked" — it's verified, not assumed.
  void _verifyAndScrollTo(GlobalKey key, {required int verifyAttemptsLeft}) {
    if (!mounted) return;
    if (_userTookOverScroll) {
      debugPrint(
        '[JournalScroll] _verifyAndScrollTo: user took over the scroll — backing off',
      );
      return;
    }
    if (verifyAttemptsLeft <= 0) {
      debugPrint(
        '[JournalScroll] _verifyAndScrollTo gave up after repeated attempts',
      );
      return;
    }
    if (!_scrollController.hasClients) {
      debugPrint(
        '[JournalScroll] _verifyAndScrollTo: scrollController has no clients yet, retrying shortly',
      );
      Future.delayed(
        const Duration(milliseconds: 150),
        () =>
            _verifyAndScrollTo(key, verifyAttemptsLeft: verifyAttemptsLeft - 1),
      );
      return;
    }
    final targetContext = key.currentContext;
    final box = targetContext?.findRenderObject();
    if (targetContext == null ||
        !targetContext.mounted ||
        box is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      // This is the actual root cause of "works from most scroll
      // positions, but not from all the way at the bottom": this
      // ListView's children aren't all kept mounted the way a plain
      // Column would be — only the ones within the current viewport (plus
      // a small cache-extent margin) actually exist as real render
      // objects at any given moment, same as ListView.builder. _reflectionKey
      // sits early on (right after the small, capped Today's Entries
      // section), so scrolling to the very bottom of a long History list
      // unmounts it entirely — key.currentContext then stays permanently
      // null, and retrying the exact same read every 150ms was never
      // going to change that on its own, since nothing was actually
      // moving the viewport toward where it lives. Forcing one coarse
      // jump toward the top (known to already comfortably contain
      // _reflectionKey, being this early in the list) gets it rebuilt so
      // the precise, verified correction below has an actual target to
      // measure on the next attempt.
      if (_scrollController.offset > 200) {
        debugPrint(
          '[JournalScroll] _verifyAndScrollTo: target not mounted and offset='
          '${_scrollController.offset} is far from top — forcing a coarse jump toward it first',
        );
        _scrollController.jumpTo(0);
      } else {
        debugPrint(
          '[JournalScroll] _verifyAndScrollTo: target not ready yet '
          '(context=${targetContext != null}, box=${box.runtimeType}), retrying shortly',
        );
      }
      Future.delayed(
        const Duration(milliseconds: 150),
        () =>
            _verifyAndScrollTo(key, verifyAttemptsLeft: verifyAttemptsLeft - 1),
      );
      return;
    }
    final viewport = RenderAbstractViewport.of(box);
    final targetOffset = viewport
        .getOffsetToReveal(box, 0.0)
        .offset
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
    final currentOffset = _scrollController.offset;
    debugPrint(
      '[JournalScroll] _verifyAndScrollTo — currentOffset=$currentOffset, targetOffset=$targetOffset, '
      'attemptsLeft=$verifyAttemptsLeft',
    );
    // Close enough to "at the top" already — done. A small tolerance
    // (not exactly 0.0) since sub-pixel rounding means an already-landed
    // scroll is rarely a perfectly exact match.
    if ((targetOffset - currentOffset).abs() < 2) {
      debugPrint('[JournalScroll] _verifyAndScrollTo: confirmed landed');
      return;
    }
    _scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .then((_) {
          debugPrint(
            '[JournalScroll] _verifyAndScrollTo: animateTo finished, '
            'offset now ${_scrollController.hasClients ? _scrollController.offset : 'no clients'} — re-verifying',
          );
          Future.delayed(
            const Duration(milliseconds: 100),
            () => _verifyAndScrollTo(
              key,
              verifyAttemptsLeft: verifyAttemptsLeft - 1,
            ),
          );
        });
  }

  void _scrollTo(GlobalKey key) {
    _userTookOverScroll = false;
    _pollAndScrollTo(key);
  }

  void _goToPage(int page) {
    // Collapses whatever was expanded too — an expanded card left over
    // from the previous page doesn't mean anything on this one.
    setState(() {
      _currentPageIndex = page;
      _expandedEntryId = null;
    });
    // Anchors back to the top on every next/prev tap — same as the
    // save-journal flows (_scrollToTop above) — so a new page's entries
    // are always reached scrolled to their start, rather than landing
    // wherever the previous page happened to leave the scroll position.
    _scrollToTop();
  }

  void _highlight(String entryId) {
    setState(() => _highlightedEntryId = entryId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightedEntryId == entryId)
        setState(() => _highlightedEntryId = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppStateScope.of(context);
    // Picks up the check-in staged from Today (see
    // AppState.handOffCheckInToJournal): its mood becomes this screen's
    // mood, and its activities merge into tags (Journal already renders
    // any tag not in _tagOptions as its own custom chip, so activities
    // like "Exercise" or "Sleep" just show up alongside Family/Work/
    // Health with no extra UI needed). `take...` clears the handoff too,
    // so this only ever applies once per check-in, not on every rebuild.
    final pending = appState.takePendingCheckIn();
    if (pending != null) {
      debugPrint(
        '[JournalScroll] didChangeDependencies: pendingCheckIn found (mood=${pending.mood}) — '
        'current widget.active=${widget.active}, scrollController.hasClients=${_scrollController.hasClients}, '
        'offset=${_scrollController.hasClients ? _scrollController.offset : 'n/a'}',
      );
      setState(() {
        _mood = pending.mood;
        _tags.addAll(pending.activities);
      });
      // "Save & Write Journal" should land you ready to type, not just
      // somewhere on the Journal tab — jump straight past today's
      // entries to the composer.
      _scrollTo(_reflectionKey);
    }

    // Picks up the id staged by "Save Mood Only" (see
    // AppState.addQuickEntry) — shows it as the current entry and
    // scrolls/highlights it for a couple seconds so it's obvious exactly
    // where the quick save landed, same as "Complete Entry" does.
    final justAddedId = appState.takeJustAddedEntryId();
    if (justAddedId != null) {
      final index = appState
          .entriesOn(DateTime.now())
          .indexWhere((e) => e.id == justAddedId);
      if (index != -1)
        setState(() => _currentPageIndex = index ~/ _entriesPerPage);
      _highlight(justAddedId);
      _scrollToTop();
    }
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switched away to another bottom-nav tab — collapse whatever entry
    // card was expanded, same as switching pages or opening/returning
    // from an entry. IndexedStack keeps this screen's State alive while
    // hidden, so nothing else would ever reset it.
    if (oldWidget.active && !widget.active && _expandedEntryId != null) {
      setState(() => _expandedEntryId = null);
    }
    // No scroll-catch-up needed here anymore — _pollAndScrollTo/
    // _pollAndScrollToTop (see their own doc) already poll widget.active
    // on every frame until it's genuinely true, so whichever one is
    // already in flight (from didChangeDependencies below) picks up this
    // exact transition on its own without this method needing to know
    // anything about it.
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _complete() {
    final appState = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    if (appState.hasReachedDailyCap(today)) {
      showAppSnackBar(
        context,
        l10n.todayEntryLimitSnackbar(AppState.maxDailyEntries),
      );
      return;
    }
    // No "you must write something" gate — a check-in's mood (and
    // whatever activities/tags came with it) is already meaningful on its
    // own; text is genuinely optional detail, not a requirement.
    final customTitle = _titleController.text.trim();
    final id = 'journal-${today.microsecondsSinceEpoch}';
    appState.addEntry(
      JournalEntry(
        id: id,
        dateTime: today,
        mood: _mood,
        title: customTitle.isEmpty ? 'Feeling ${_mood.label}' : customTitle,
        text: _textController.text.trim(),
        tags: _tags.toList(),
        // Copy, not the live list — _photos gets cleared right below to
        // reset the composer, and without a copy that clear would mutate
        // the exact same list this just-saved entry is holding onto.
        photos: List<String>.from(_photos),
        voiceNote: _voiceNote,
        themeName: _themeName,
      ),
    );
    showAppSnackBar(context, l10n.journalEntrySavedSnackbar);
    setState(() {
      _textController.clear();
      _titleController.clear();
      _tags.clear();
      // Writing Theme deliberately isn't reset — it carries over as the
      // starting point for the next entry instead of snapping back to
      // the default every time.
      _photos.clear();
      _voiceNote = null;
      // The new entry is always last (entriesOn sorts ascending by time).
      _currentPageIndex =
          (appState.entriesOn(today).length - 1) ~/ _entriesPerPage;
    });
    // Scrolls back up to show the freshly-created entry, the same way
    // "Save Mood Only" does — so completing an entry visibly confirms it
    // was created, not just a snackbar that scrolls past.
    _highlight(id);
    _scrollToTop();
  }

  Future<void> _addPhoto() async {
    // Belt-and-suspenders: the "Add More" tile is already hidden once the
    // cap is hit, so this is only reachable if something else ever calls
    // _addPhoto directly.
    if (_photos.length >= JournalEntry.maxPhotos) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.journalPhotoCap(JournalEntry.maxPhotos),
      );
      return;
    }
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final photo = await pickPhotoAsBase64(source);
    if (photo != null && mounted) setState(() => _photos.add(photo));
  }

  Future<void> _recordVoiceNote() async {
    final voiceNote = await showVoiceRecorderSheet(context);
    if (voiceNote != null && mounted) setState(() => _voiceNote = voiceNote);
  }

  void _confirmTag() {
    final value = _tagController.text.trim();
    if (value.isEmpty) return;
    final customCount = _tags.where((t) => !_tagOptions.contains(t)).length;
    if (customCount >= _maxCustomTags) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.journalCustomTagCap(_maxCustomTags),
      );
      return;
    }
    setState(() {
      _tags.add(value);
      _tagController.clear();
      _showTagField = false;
    });
  }

  // Background for the content editor and the tag input — themed to
  // actually show the selected Writing Theme swatch's color, the same
  // low-alpha blend used everywhere else a Writing Theme tints a card.
  // "White" resolves to a plain, literal white in light mode — no
  // special-casing needed to keep it visible now that the app's own
  // background is a warm cream (not a near-white surface anymore), so a
  // genuinely white card already reads as its own distinct, visible
  // "card" against it. Dark mode still needs no exception either —
  // resolveJournalThemeColor already resolves White to black there,
  // which blends in as a visible (if subtle) darkening, not nothing.
  Color _composerFillColor(ColorScheme scheme) {
    if (_themeName == null) return scheme.surfaceContainerLowest;
    return Color.alphaBlend(
      resolveJournalThemeColor(
        _themeName!,
        scheme.brightness,
      ).withValues(alpha: 0.35),
      scheme.surfaceContainerLowest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final today = DateTime.now();
    final todaysEntries = appState.entriesOn(today);

    return NotificationListener<ScrollNotification>(
      // dragDetails is only non-null for a real touch-initiated scroll —
      // any of this screen's own animateTo/jumpTo calls report null there,
      // so this only ever fires on an actual user gesture. See
      // _userTookOverScroll's own doc for why that distinction matters:
      // without it, this screen's auto-scroll retry loops couldn't tell
      // "my own animation finished" apart from "the user just grabbed the
      // list and scrolled somewhere else", and would try to animate back
      // to the target again regardless — fighting a genuine scroll for the
      // rest of their retry budget instead of just backing off.
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _userTookOverScroll = true;
        }
        return false;
      },
      child: ListView(
        controller: _scrollController,
        // Fixed padding, not device-inset-driven — a flat constant
        // sidesteps needing any device inset reporting to be reliable at
        // all (see Today's own fix for the same reasoning). Top matches
        // Insights' own top-level padding exactly (8) — a real
        // side-by-side comparison on-device showed 12 still reading as a
        // visibly bigger gap under LuminaTopBar than Insights has, even
        // though both sit under the exact same app bar.
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.journalTodaysEntries,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              EntriesHistoryRow(
                entryCount: todaysEntries.length,
                onHistoryTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeletedEntriesScreen(day: today),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            key: _carouselKey,
            child: todaysEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.journalNothingLoggedYet,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      // Pages of up to _entriesPerPage entries each — not
                      // one entry per page, so 2 entries (say) is just one
                      // page showing both, and pagination only kicks in
                      // once there's enough to actually need it. With the
                      // 10/day cap and 5 per page that's 2 pages, tops.
                      final pageCount = (todaysEntries.length / _entriesPerPage)
                          .ceil();
                      final page = (_currentPageIndex ?? pageCount - 1).clamp(
                        0,
                        pageCount - 1,
                      );
                      final pageStart = page * _entriesPerPage;
                      final pageEnd = (pageStart + _entriesPerPage).clamp(
                        0,
                        todaysEntries.length,
                      );
                      final pageEntries = todaysEntries.sublist(
                        pageStart,
                        pageEnd,
                      );
                      return Column(
                        children: [
                          for (final entry in pageEntries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TimelineRow(
                                key: ValueKey(entry.id),
                                entry: entry,
                                highlighted: entry.id == _highlightedEntryId,
                                expanded: entry.id == _expandedEntryId,
                                onToggleExpand: () => setState(
                                  () => _expandedEntryId =
                                      _expandedEntryId == entry.id
                                      ? null
                                      : entry.id,
                                ),
                                onOpened: () {
                                  if (mounted)
                                    setState(() => _expandedEntryId = null);
                                },
                              ),
                            ),
                          if (pageCount > 1) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hidden rather than just disabled at the ends —
                                // maintainSize keeps its slot reserved so the
                                // dots don't jump sideways when it disappears.
                                Visibility(
                                  visible: page > 0,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: IconButton(
                                    onPressed: page > 0
                                        ? () => _goToPage(page - 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: l10n.deletedEntriesPrevPage,
                                  ),
                                ),
                                for (var i = 0; i < pageCount; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i == page
                                            ? scheme.primary
                                            : scheme.surfaceContainerHighest,
                                      ),
                                    ),
                                  ),
                                Visibility(
                                  visible: page < pageCount - 1,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: IconButton(
                                    onPressed: page < pageCount - 1
                                        ? () => _goToPage(page + 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: l10n.deletedEntriesNextPage,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            l10n.journalDailySlots(
                              todaysEntries.length,
                              AppState.maxDailyEntries,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          const _DailyReflectionBar(),
          const SizedBox(height: 24),
          KeyedSubtree(
            key: _reflectionKey,
            child: Text(
              l10n.journalReflectionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.journalWritingTheme,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final entry in journalThemes.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ThemeSwatch(
                    color: resolveJournalThemeColor(
                      entry.key,
                      scheme.brightness,
                    ),
                    selected: _themeName == entry.key,
                    // Always selects, never toggles off — a theme is
                    // always in effect, there's no "none" state.
                    onTap: () => setState(() => _themeName = entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.journalTitleFieldLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _titleController,
              maxLength: _maxTitleLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                // Without this, the global theme's own filled/fillColor
                // (a light grey) painted right over this field's parent
                // Container, which already sets a plain white background —
                // the title looked grey no matter what, since the
                // TextField's own fill was covering it up every time.
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintText: l10n.journalTitleHint,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _composerFillColor(scheme),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                TextField(
                  controller: _textController,
                  minLines: 8,
                  maxLines: 12,
                  maxLength: _maxJournalLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: l10n.journalWriteHint,
                    contentPadding: EdgeInsets.zero,
                    // Built-in counter is suppressed here and shown as our
                    // own right-aligned caption below the box instead — the
                    // default one would land underneath/behind the "Feeling"
                    // chip that's already Positioned over this field.
                    counterText: '',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: PopupMenuButton<Mood>(
                    initialValue: _mood,
                    onSelected: (mood) => setState(() => _mood = mood),
                    itemBuilder: (context) => [
                      for (final mood in Mood.values)
                        PopupMenuItem(
                          value: mood,
                          child: Row(
                            children: [
                              // Same mood-swatch color language as the entry
                              // cards and the mood picker on Today — this
                              // list read as plain text before, with nothing
                              // tying each row to its actual color anywhere
                              // else in the app.
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: mood.swatch,
                                child: MoodEmoji(mood: mood, size: 12),
                              ),
                              const SizedBox(width: 10),
                              Text(moodLabel(context, mood)),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        // mood.swatch itself is a pale pastel — fine as a
                        // fill, but as a thin 2px line it barely read as
                        // colored at all. Using it for the inner background
                        // instead (a light tint, not full-strength) and the
                        // much more saturated onSwatch for the actual
                        // border line is what makes both halves — fill and
                        // outline — actually look tied to the mood's color.
                        color: _mood.swatch.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _mood.onSwatch, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.journalFeelingLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          MoodEmoji(mood: _mood, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, _) => Text(
                  '${value.text.length} / $_maxJournalLength',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _photos.isEmpty
                ? l10n.journalPhotosLabel
                : l10n.journalPhotosLabelCount(
                    _photos.length,
                    JournalEntry.maxPhotos,
                  ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  _photos.length +
                  (_photos.length < JournalEntry.maxPhotos ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == _photos.length) {
                  return AddPhotoTile(
                    label: _photos.isEmpty
                        ? l10n.journalAddPhoto
                        : l10n.journalAddMorePhoto,
                    onTap: _addPhoto,
                  );
                }
                return PhotoTile(
                  base64Photo: _photos[index],
                  onRemove: () => setState(() => _photos.removeAt(index)),
                );
              },
            ),
          ),
          if (_voiceNote == null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              // Solid, matching the same button on the entry detail screen.
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              onPressed: _recordVoiceNote,
              icon: const Icon(Icons.mic),
              label: Text(l10n.journalVoiceNoteButton),
            ),
          ],
          if (_voiceNote != null) ...[
            const SizedBox(height: 12),
            VoiceNotePlayer(
              base64Audio: _voiceNote!,
              onDelete: () => setState(() => _voiceNote = null),
              // Plain white always, same as the tag chips and tag input
              // right below it — see their own unselectedColor comment for
              // why this deliberately ignores _composerFillColor's Writing
              // Theme tint instead of following it.
              backgroundColor: scheme.surfaceContainerLowest,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.journalTagsLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tagOptions)
                _TagChip(
                  label: activityLabel(context, tag),
                  selected: _tags.contains(tag),
                  // Plain white always — not _composerFillColor, which
                  // follows whichever Writing Theme is currently picked
                  // (right for the title/body/tag-input fields, which are
                  // meant to wash with the theme, but wrong here: it made
                  // an unselected tag pick up e.g. a yellow/tan tint under
                  // the Yellow/Sunset themes instead of staying neutral).
                  unselectedColor: scheme.surfaceContainerLowest,
                  onTap: () => setState(() {
                    if (!_tags.remove(tag)) _tags.add(tag);
                  }),
                ),
              for (final tag in _tags.where((t) => !_tagOptions.contains(t)))
                _TagChip(
                  label: activityLabel(context, tag),
                  selected: true,
                  unselectedColor: scheme.surfaceContainerLowest,
                  onTap: () => setState(() => _tags.remove(tag)),
                ),
              // Hidden once at the custom-tag cap, rather than still
              // inviting a tap that _confirmTag would just reject.
              if (_tags.where((t) => !_tagOptions.contains(t)).length <
                  _maxCustomTags)
                InkWell(
                  onTap: () => setState(() => _showTagField = !_showTagField),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 2),
                    ),
                    child: Icon(Icons.add, size: 18, color: scheme.primary),
                  ),
                ),
            ],
          ),
          if (_showTagField) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    autofocus: true,
                    maxLength: _maxTagLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      hintText: l10n.journalAddTagHint,
                      counterText: '',
                      // Plain white always, like the tag chips next to it
                      // (see their own unselectedColor comment) — not
                      // _composerFillColor, which would pick up whichever
                      // Writing Theme's tint (e.g. Yellow) is selected.
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                    ),
                    // Enter/"Done" on the keyboard confirms...
                    onSubmitted: (_) => _confirmTag(),
                  ),
                ),
                // ...and so does this tick, for anyone who'd rather tap
                // than reach for the keyboard's enter/done key.
                InkWell(
                  onTap: _confirmTag,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.check_circle, color: scheme.primary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                // Dimmed but still tappable at the cap — same reasoning as
                // Today's Save buttons: a hard-disabled button couldn't
                // show _complete()'s "limit reached" reminder on tap.
                AnimatedOpacity(
                  opacity: appState.hasReachedDailyCap(today) ? 0.5 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                    ),
                    onPressed: _complete,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      l10n.journalSaveButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (appState.hasReachedDailyCap(today)) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.todayEntryLimitBanner(AppState.maxDailyEntries),
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact expand/collapse bar for the day's writing prompt — a full
/// card felt like too much space for what's often a one-liner; this
/// stays a single row until there's actually more to reveal.
class _DailyReflectionBar extends StatefulWidget {
  const _DailyReflectionBar();

  @override
  State<_DailyReflectionBar> createState() => _DailyReflectionBarState();
}

class _DailyReflectionBarState extends State<_DailyReflectionBar> {
  bool _expanded = false;
  String? _lastCheckedLanguage;

  // Preloaded pool used whenever Gemini isn't available — no API key, no
  // connection, or the quota's been used up. Picked deterministically by
  // day-of-year (not random) so it still rotates day to day rather than
  // always landing on the same one, and stays consistent if the app
  // reloads partway through the same day.
  String _localFallback(AppLocalizations l10n) {
    final fallbackPrompts = [
      l10n.journalReflectionFallback1,
      l10n.journalReflectionFallback2,
      l10n.journalReflectionFallback3,
      l10n.journalReflectionFallback4,
      l10n.journalReflectionFallback5,
      l10n.journalReflectionFallback6,
      l10n.journalReflectionFallback7,
    ];
    final dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    return fallbackPrompts[dayOfYear % fallbackPrompts.length];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tracks which language was last checked (not just "has this ever
    // run") — Localizations.localeOf changing (Settings' language
    // picker) fires didChangeDependencies again, and a cached prompt
    // from before that switch is for the *wrong* language now, so this
    // deliberately re-checks (and, if needed, regenerates) rather than
    // running only once per widget lifetime.
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_lastCheckedLanguage == languageCode) return;
    _lastCheckedLanguage = languageCode;
    final appState = AppStateScope.of(context);
    // Already generated/picked for today, in this language — nothing to do.
    if (appState.todaysReflectionPrompt(languageCode) != null) return;

    final apiKey = resolveGeminiApiKey(appState.geminiApiKey);
    if (apiKey == null) {
      // Deferred — didChangeDependencies runs while this widget (and,
      // since HomeShell builds every tab at once via IndexedStack, that
      // means right after every single login) is still in its *first*
      // build/mount pass. Calling a notifyListeners()-triggering setter
      // synchronously here throws "setState() or markNeedsBuild() called
      // during build", because it tries to re-dirty AppStateScope — an
      // ancestor that already finished building earlier this same frame
      // — from a descendant that's still mounting. Waiting for the frame
      // to actually finish first avoids that entirely.
      final l10n = AppLocalizations.of(context)!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appState.setTodaysReflectionPrompt(_localFallback(l10n), languageCode);
      });
      return;
    }
    fetchDailyReflectionPrompt(apiKey, languageCode)
        .then((prompt) {
          if (!mounted) return;
          appState.setTodaysReflectionPrompt(prompt, languageCode);
        })
        .catchError((_) {
          // Quota hit, network hiccup, whatever — the local pool means this
          // bar is never just empty or stuck loading.
          if (!mounted) return;
          appState.setTodaysReflectionPrompt(
            _localFallback(AppLocalizations.of(context)!),
            languageCode,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    // Shows a real prompt immediately even before today's has finished
    // generating/persisting (see didChangeDependencies above) — falls
    // back to the same deterministic local pick build() would land on
    // anyway, so there's no flash of empty content while Gemini's call
    // is still in flight.
    final prompt =
        AppStateScope.of(context).todaysReflectionPrompt(languageCode) ??
        _localFallback(l10n);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, size: 18, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.journalDailyReflection,
                    style: TextStyle(
                      color: scheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"$prompt"',
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                _expanded ? Icons.expand_less : Icons.chevron_right,
                size: 20,
                color: scheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.entry,
    this.highlighted = false,
    required this.expanded,
    required this.onToggleExpand,
    required this.onOpened,
  });

  final JournalEntry entry;

  /// Briefly true right after this entry was created via "Save Mood
  /// Only" — see JournalScreen's didChangeDependencies.
  final bool highlighted;

  /// Whether this card is the one currently expanded — only one entry
  /// card is ever expanded at a time, tracked by the parent so expanding
  /// one collapses whichever was open before.
  final bool expanded;
  final VoidCallback onToggleExpand;

  /// Called after returning from viewing/editing this entry, so the
  /// parent can collapse whatever was expanded — an expanded preview
  /// shouldn't stick around once you've navigated away and back.
  final VoidCallback onOpened;

  static const _collapsedTagCount = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = entry.labels;

    // A "Feeling {mood}" subtitle is only worth showing when the title
    // isn't already that exact string (i.e. a custom title was given) —
    // otherwise it'd just repeat the title back verbatim underneath it.
    final hasCustomTitle = entry.title != 'Feeling ${entry.mood.label}';

    final visibleTags = expanded
        ? labels
        : labels.take(_collapsedTagCount).toList();
    final hiddenTagCount = labels.length - visibleTags.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        confirmDismiss: (_) async {
          final appState = AppStateScope.of(context);
          if (appState.hasReachedDeletedCap(entry.dateTime)) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deletedHistoryFullTitle),
                content: Text(
                  l10n.deletedHistoryFullBody(AppState.maxDeletedEntriesPerDay),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionOk),
                  ),
                ],
              ),
            );
            return false;
          }
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.entryDeleteConfirmTitle),
              content: Text(
                l10n.journalDeleteConfirmBody(
                  entryDisplayTitle(context, entry),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.actionNo),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.actionYesDelete,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) {
          AppStateScope.of(context).deleteEntry(entry.id);
          showAppSnackBar(context, l10n.entryDeletedSnackbar);
        },
        child: Material(
          // Mood-tinted like Calendar's day-view card, instead of a flat
          // neutral gray — the two lists should read as the same kind of
          // card wherever an entry shows up. Darker fill + a clearly
          // visible border (was 0.15/0.3 — read as too washed-out/pale to
          // stand out against the app's own cream background) than the
          // original mockup's much subtler tint.
          color: entry.mood.swatch.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EntryDetailScreen(entryId: entry.id),
                ),
              );
              onOpened();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // onSwatch (mood's own dark contrast color), not swatch
                // itself — swatch is a pale pastel, so even at full
                // opacity it never reads as a genuinely darker tone, just
                // a less transparent version of the same pale color.
                border: Border.all(
                  color: highlighted
                      ? scheme.primary
                      : entry.mood.onSwatch.withValues(alpha: 0.55),
                  width: highlighted ? 2 : 1.5,
                ),
              ),
              // Needs the card's actual available width to tell whether
              // entry.text would really wrap/truncate at one line — a
              // short one-liner like "jjj." never would, and the
              // expand/collapse chevron would just toggle between two
              // identical-looking states, so it's only worth showing
              // when there's something real for it to reveal.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const previewStyle = TextStyle(fontSize: 13, height: 1.4);
                  final textOverflows =
                      entry.text.isNotEmpty &&
                      textOverflowsOneLine(
                        entry.text,
                        previewStyle,
                        constraints.maxWidth,
                      );
                  final hasOverflow =
                      textOverflows || labels.length > _collapsedTagCount;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: entry.mood.swatch,
                            child: Icon(
                              entry.mood.icon,
                              size: 18,
                              color: entry.mood.onSwatch,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entryDisplayTitle(context, entry),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (hasCustomTitle) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.entryFeelingMood(
                                      moodLabel(context, entry.mood),
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.photos.isNotEmpty) ...[
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (entry.voiceNote != null) ...[
                            Icon(
                              Icons.mic,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            DateFormat(
                              'h:mm a',
                              Localizations.localeOf(context).toString(),
                            ).format(entry.dateTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          if (hasOverflow)
                            IconButton(
                              onPressed: onToggleExpand,
                              icon: Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                              tooltip: expanded
                                  ? l10n.entryShowLess
                                  : l10n.entryShowMore,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                        ],
                      ),
                      if (entry.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          // Even expanded, this is still just a preview card —
                          // capped to the first 100 words instead of the
                          // entry's entire text. maxLines below is capped to
                          // match Deleted Entries' own preview (3 lines) —
                          // it's also the real backstop for pathological
                          // input (one giant run of characters with no
                          // spaces), which word-splitting alone can't catch.
                          expanded
                              ? truncateWords(entry.text, 100)
                              : entry.text,
                          maxLines: expanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: previewStyle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final label in visibleTags)
                              MiniChip(label: activityLabel(context, label)),
                            if (!expanded && hiddenTagCount > 0)
                              const MiniChip(label: '...'),
                          ],
                        ),
                      ],
                      if (entry.photos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        PhotoStrip(photos: entry.photos),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.unselectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Background for the *unselected* state — defaults to the plain
  /// neutral grey if not given. The selected state keeps its own fixed
  /// green tint regardless (that's a meaningful "this one's picked"
  /// signal, not a theme-following background), so only this one
  /// follows the composer's current Writing Theme.
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.5)
              : (unselectedColor ?? scheme.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
