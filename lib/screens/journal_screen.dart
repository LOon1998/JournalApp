import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../services/media_capture.dart';
import '../services/text_measure.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/entries_history_row.dart';
import '../widgets/mini_chip.dart';
import '../widgets/photo_tile.dart';
import '../widgets/theme_swatch.dart';
import '../widgets/voice_note_player.dart';
import '../widgets/voice_recorder_sheet.dart';
import 'deleted_entries_screen.dart';
import 'entry_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

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
  static const _maxTitleLength = 60;

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

  // Scroll targets: _carouselKey for "Complete Entry"/"Save Mood Only"
  // (brings today's entries back into view), _reflectionKey for "Save &
  // Write Journal" (jumps straight to the composer).
  final _carouselKey = GlobalKey();
  final _reflectionKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    void attempt() {
      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        // alignment: 0 anchors the target to the *top* of the viewport
        // (not centered) — "Save & Write Journal" should land right at
        // the composer heading, and "Complete Entry" right at the top of
        // today's entries, not somewhere in the middle of the screen.
        Scrollable.ensureVisible(targetContext,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0);
      }
    }

    // Complete Entry is pressed straight out of the text field — on a
    // real phone browser, the on-screen keyboard's own dismiss animation
    // (outside Flutter's control, and highly device/browser dependent)
    // can still be resizing the viewport well after any one fixed delay
    // we guess, which throws off ensureVisible's math or gets silently
    // overridden once the resize actually finishes. Unfocusing first,
    // then attempting the scroll both immediately *and* again after a
    // delay, means it lands correctly whichever one actually mattered —
    // immediately when there's no keyboard involved (Save Mood Only,
    // Save & Write Journal), and the retry corrects for a slow keyboard
    // dismiss when there is one (Complete Entry).
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    Future.delayed(const Duration(milliseconds: 400), attempt);
  }

  void _goToPage(int page) {
    // Just switches pages in place — no scrolling/anchoring. The
    // reflowed content below (Daily Reflection, Journal Reflection, ...)
    // shifting slightly is expected/fine; jumping the scroll position on
    // every next/prev tap was the more jarring behavior.
    setState(() => _currentPageIndex = page);
  }

  void _highlight(String entryId) {
    setState(() => _highlightedEntryId = entryId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightedEntryId == entryId) setState(() => _highlightedEntryId = null);
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
      final index = appState.entriesOn(DateTime.now()).indexWhere((e) => e.id == justAddedId);
      if (index != -1) setState(() => _currentPageIndex = index ~/ _entriesPerPage);
      _highlight(justAddedId);
      _scrollTo(_carouselKey);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _complete() {
    final appState = AppStateScope.of(context);
    final today = DateTime.now();
    if (appState.hasReachedDailyCap(today)) {
      showAppSnackBar(
          context, "Today's ${AppState.maxDailyEntries}-entry limit is reached — delete one to add another.");
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
    showAppSnackBar(context, 'Entry saved to your journal \u{1F4D6}');
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
      _currentPageIndex = (appState.entriesOn(today).length - 1) ~/ _entriesPerPage;
    });
    // Scrolls back up to show the freshly-created entry, the same way
    // "Save Mood Only" does — so completing an entry visibly confirms it
    // was created, not just a snackbar that scrolls past.
    _highlight(id);
    _scrollTo(_carouselKey);
  }

  Future<void> _addPhoto() async {
    // Belt-and-suspenders: the "Add More" tile is already hidden once the
    // cap is hit, so this is only reachable if something else ever calls
    // _addPhoto directly.
    if (_photos.length >= JournalEntry.maxPhotos) {
      showAppSnackBar(context, 'Up to ${JournalEntry.maxPhotos} photos per entry');
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
      showAppSnackBar(context, 'Up to $_maxCustomTags custom tags');
      return;
    }
    setState(() {
      _tags.add(value);
      _tagController.clear();
      _showTagField = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final today = DateTime.now();
    final todaysEntries = appState.entriesOn(today);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Entries", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            EntriesHistoryRow(
              entryCount: todaysEntries.length,
              onHistoryTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DeletedEntriesScreen(day: today)),
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
                  child: Text('Nothing logged yet today.', style: TextStyle(color: scheme.onSurfaceVariant)),
                )
              : Builder(
                  builder: (context) {
                    // Pages of up to _entriesPerPage entries each — not
                    // one entry per page, so 2 entries (say) is just one
                    // page showing both, and pagination only kicks in
                    // once there's enough to actually need it. With the
                    // 10/day cap and 5 per page that's 2 pages, tops.
                    final pageCount = (todaysEntries.length / _entriesPerPage).ceil();
                    final page = (_currentPageIndex ?? pageCount - 1).clamp(0, pageCount - 1);
                    final pageStart = page * _entriesPerPage;
                    final pageEnd = (pageStart + _entriesPerPage).clamp(0, todaysEntries.length);
                    final pageEntries = todaysEntries.sublist(pageStart, pageEnd);
                    return Column(
                      children: [
                        for (final entry in pageEntries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TimelineRow(
                              key: ValueKey(entry.id),
                              entry: entry,
                              highlighted: entry.id == _highlightedEntryId,
                            ),
                          ),
                        if (pageCount > 1) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page > 0 ? () => _goToPage(page - 1) : null,
                                icon: const Icon(Icons.chevron_left),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Previous page',
                              ),
                              for (var i = 0; i < pageCount; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == page ? scheme.primary : scheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ),
                              IconButton(
                                onPressed: page < pageCount - 1 ? () => _goToPage(page + 1) : null,
                                icon: const Icon(Icons.chevron_right),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Next page',
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text('${todaysEntries.length} of ${AppState.maxDailyEntries} daily slots',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
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
          child: Text('Journal Reflection',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 24),
        Text('Writing Theme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final entry in journalThemes.entries)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ThemeSwatch(
                  color: resolveJournalThemeColor(entry.key, scheme.brightness),
                  selected: _themeName == entry.key,
                  // Always selects, never toggles off — a theme is
                  // always in effect, there's no "none" state.
                  onTap: () => setState(() => _themeName = entry.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Journal Title (Optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            controller: _titleController,
            maxLength: _maxTitleLength,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Title your entry...',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _themeName == null
                ? scheme.surfaceContainerLowest
                : Color.alphaBlend(
                    resolveJournalThemeColor(_themeName!, scheme.brightness).withValues(alpha: 0.35),
                    scheme.surfaceContainerLowest),
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
                style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  hintText: 'Write your thoughts here...',
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
                      PopupMenuItem(value: mood, child: Text('${mood.emoji}  ${mood.label}')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.surfaceContainerHighest),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Feeling:', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        Text(_mood.emoji, style: const TextStyle(fontSize: 18)),
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
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _photos.isEmpty ? 'Photos (Optional)' : 'Photos (Optional) · ${_photos.length}/${JournalEntry.maxPhotos}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length + (_photos.length < JournalEntry.maxPhotos ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _photos.length) {
                return AddPhotoTile(
                  label: _photos.isEmpty ? 'Add Photo' : 'Add More',
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
            label: const Text('Voice Note'),
          ),
        ],
        if (_voiceNote != null) ...[
          const SizedBox(height: 12),
          VoiceNotePlayer(
            base64Audio: _voiceNote!,
            onDelete: () => setState(() => _voiceNote = null),
          ),
        ],
        const SizedBox(height: 24),
        Text('Tags (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in _tagOptions)
              _TagChip(
                label: tag,
                selected: _tags.contains(tag),
                onTap: () => setState(() {
                  if (!_tags.remove(tag)) _tags.add(tag);
                }),
              ),
            for (final tag in _tags.where((t) => !_tagOptions.contains(t)))
              _TagChip(label: tag, selected: true, onTap: () => setState(() => _tags.remove(tag))),
            // Hidden once at the custom-tag cap, rather than still
            // inviting a tap that _confirmTag would just reject.
            if (_tags.where((t) => !_tagOptions.contains(t)).length < _maxCustomTags)
              InkWell(
                onTap: () => setState(() => _showTagField = !_showTagField),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant, width: 2),
                  ),
                  child: Icon(Icons.add, size: 18, color: scheme.outlineVariant),
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
                  decoration: const InputDecoration(hintText: 'Add a tag'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  ),
                  onPressed: _complete,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              if (appState.hasReachedDailyCap(today)) ...[
                const SizedBox(height: 8),
                Text("Today's ${AppState.maxDailyEntries}-entry limit is reached.",
                    style: TextStyle(fontSize: 12, color: scheme.error)),
              ],
            ],
          ),
        ),
      ],
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
  // TODO: rotate daily rather than a single fixed prompt, if/when there's
  // a bank of these to pick from.
  static const _prompt = "What's one small thing that made you smile today?";

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  Text('DAILY REFLECTION',
                      style: TextStyle(
                          color: scheme.secondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text('"$_prompt"',
                      maxLines: _expanded ? null : 1,
                      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_expanded ? Icons.expand_less : Icons.chevron_right, size: 20, color: scheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({super.key, required this.entry, this.highlighted = false});

  final JournalEntry entry;

  /// Briefly true right after this entry was created via "Save Mood
  /// Only" — see JournalScreen's didChangeDependencies.
  final bool highlighted;

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  static const _collapsedTagCount = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final scheme = Theme.of(context).colorScheme;
    final labels = entry.labels;

    // A "Feeling {mood}" subtitle is only worth showing when the title
    // isn't already that exact string (i.e. a custom title was given) —
    // otherwise it'd just repeat the title back verbatim underneath it.
    final hasCustomTitle = entry.title != 'Feeling ${entry.mood.label}';

    final visibleTags = _expanded ? labels : labels.take(_collapsedTagCount).toList();
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
                title: const Text('Deleted history is full'),
                content: Text(
                    "This day's History already has ${AppState.maxDeletedEntriesPerDay} deleted entries. Restore or permanently delete some from History before deleting another."),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              ),
            );
            return false;
          }
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete entry?'),
              content: Text('Remove "${entry.title}" from your timeline? You can restore it later from History.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Yes, delete', style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) {
          AppStateScope.of(context).deleteEntry(entry.id);
          showAppSnackBar(context, 'Entry deleted');
        },
        child: Material(
          // Mood-tinted like Calendar's day-view card, instead of a flat
          // neutral gray — the two lists should read as the same kind of
          // card wherever an entry shows up.
          color: entry.mood.swatch.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.highlighted ? scheme.primary : entry.mood.swatch.withValues(alpha: 0.3),
                  width: widget.highlighted ? 2 : 1,
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
                  final textOverflows = entry.text.isNotEmpty &&
                      textOverflowsOneLine(entry.text, previewStyle, constraints.maxWidth);
                  final hasOverflow = textOverflows || labels.length > _collapsedTagCount;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: entry.mood.swatch,
                            child: Icon(entry.mood.icon, size: 18, color: entry.mood.onSwatch),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                if (hasCustomTitle) ...[
                                  const SizedBox(height: 2),
                                  Text('Feeling ${entry.mood.label}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.photos.isNotEmpty) ...[
                            Icon(Icons.photo_camera_outlined, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                          ],
                          if (entry.voiceNote != null) ...[
                            Icon(Icons.mic, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                          ],
                          Text(DateFormat('h:mm a').format(entry.dateTime),
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                          if (hasOverflow)
                            IconButton(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                                  size: 20, color: scheme.onSurfaceVariant),
                              tooltip: _expanded ? 'Show less' : 'Show more',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                      if (entry.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          entry.text,
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: previewStyle.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final label in visibleTags) MiniChip(label: label),
                            if (!_expanded && hiddenTagCount > 0) const MiniChip(label: '...'),
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
  const _TagChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
      ),
    );
  }
}
