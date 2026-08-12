import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../services/media_capture.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/photo_tile.dart';
import '../widgets/theme_swatch.dart';
import '../widgets/voice_note_player.dart';
import '../widgets/voice_recorder_sheet.dart';

/// Full-page detail/edit view for a single entry — reached by tapping an
/// entry on the Journal timeline or a Calendar day-detail card (as
/// opposed to the small inline expand/collapse chevron each row already
/// has, which stays for a quick peek without leaving the list). Also
/// reached from the Deleted Entries history, in which case the entry is
/// shown read-only — [JournalEntry.isDeleted] gates every editing
/// affordance (mood, title, tags, photos, voice note, and the edit FAB
/// itself) off, since a deleted entry has no business being edited in
/// place before it's restored.
///
/// Looks the entry up live by [entryId] every build rather than holding a
/// snapshot passed in from the caller, so edits/restores/deletes made
/// elsewhere (or on this very screen) stay in sync without extra plumbing.
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  // Matches the limit on Journal's own composer — see the comment there
  // for why (generous safety ceiling, not a real writing limit).
  static const _maxTextLength = 5000;

  // Matches Journal composer's title cap — see the comment there.
  static const _maxTitleLength = 40;

  // Journal's composer caps *custom* tags at 8 (on top of its 3 fixed
  // presets); this screen has no preset/custom split, so the same 8
  // applies to the total here instead — same reasoning (an unbounded
  // tag list pushes the screen into an ever-longer scroll).
  static const _maxTags = 8;

  bool _editingText = false;
  final _textController = TextEditingController();

  bool _editingTitle = false;
  final _titleController = TextEditingController();

  // Snapshots taken when edit mode starts, restored on Cancel. Unlike the
  // body text (which lives only in _textController until Save), photos,
  // the title tick, tags, and the voice note all commit to the entry
  // immediately when touched — so Cancel has to actively put each of
  // these back, or changes made mid-edit would silently stick instead of
  // being discarded along with everything else.
  List<String>? _photosSnapshot;
  List<String>? _tagsSnapshot;
  List<String>? _activitiesSnapshot;
  String? _voiceNoteSnapshot;
  String? _titleSnapshot;
  String? _themeNameSnapshot;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  JournalEntry? _findEntry(AppState appState) {
    for (final e in appState.entries) {
      if (e.id == widget.entryId) return e;
    }
    for (final e in appState.deletedEntries) {
      if (e.id == widget.entryId) return e;
    }
    return null;
  }

  void _startEditingText(JournalEntry entry) {
    _textController.text = entry.text;
    _photosSnapshot = List<String>.from(entry.photos);
    _tagsSnapshot = List<String>.from(entry.tags);
    _activitiesSnapshot = List<String>.from(entry.activities);
    _voiceNoteSnapshot = entry.voiceNote;
    _titleSnapshot = entry.title;
    _themeNameSnapshot = entry.themeName;
    setState(() => _editingText = true);
  }

  void _saveText(BuildContext context, AppState appState, JournalEntry entry) {
    appState.updateEntry(entry.id, text: _textController.text.trim());
    // Leaving edit mode retires the title editor too, if it was left
    // mid-edit — save it rather than silently abandoning it.
    if (_editingTitle) _saveTitle(appState, entry);
    showAppSnackBar(context, 'Entry saved');
    setState(() {
      _editingText = false;
      _photosSnapshot = null;
      _tagsSnapshot = null;
      _activitiesSnapshot = null;
      _voiceNoteSnapshot = null;
      _titleSnapshot = null;
      _themeNameSnapshot = null;
    });
  }

  void _cancelEditingText(AppState appState, JournalEntry entry) {
    // The written text was only ever a draft (in _textController) until
    // Save, so cancelling that is just dropping the draft. Everything
    // else below commits to the entry immediately as soon as it's
    // touched, rather than staying local — so cancelling has to actively
    // restore each one's snapshot from when editing started, or changes
    // made mid-edit would silently stick around.
    if (_photosSnapshot != null) appState.setPhotos(entry.id, _photosSnapshot!);
    if (_tagsSnapshot != null && _activitiesSnapshot != null) {
      appState.setLabels(entry.id, _tagsSnapshot!, _activitiesSnapshot!);
    }
    // _voiceNoteSnapshot itself may legitimately be null (no voice note
    // when editing started) — that's still a real snapshot to restore to,
    // just via removeVoiceNote instead of setVoiceNote.
    if (_titleSnapshot != null) {
      final snapshotVoiceNote = _voiceNoteSnapshot;
      if (snapshotVoiceNote != null) {
        appState.setVoiceNote(entry.id, snapshotVoiceNote);
      } else {
        appState.removeVoiceNote(entry.id);
      }
      appState.updateEntry(entry.id, title: _titleSnapshot!);
      // Same "may legitimately be null" situation as the voice note —
      // an entry with no Writing Theme ever set restores to that, not
      // to whatever was picked mid-edit.
      final snapshotTheme = _themeNameSnapshot;
      if (snapshotTheme != null) {
        appState.updateEntry(entry.id, themeName: snapshotTheme);
      } else {
        appState.updateEntry(entry.id, clearThemeName: true);
      }
    }
    setState(() {
      _editingText = false;
      _textController.text = entry.text;
      _editingTitle = false;
      _titleController.text = _titleSnapshot ?? entry.title;
      _photosSnapshot = null;
      _tagsSnapshot = null;
      _activitiesSnapshot = null;
      _voiceNoteSnapshot = null;
      _titleSnapshot = null;
      _themeNameSnapshot = null;
    });
  }

  void _startEditingTitle(JournalEntry entry) {
    _titleController.text = entry.title;
    setState(() => _editingTitle = true);
  }

  // No separate cancel here (unlike the body text editor) — tapping away
  // always confirms, same as the tag "+" field below. Saving a blank title
  // just falls back to the mood-based default rather than leaving the
  // entry with an empty headline.
  void _saveTitle(AppState appState, JournalEntry entry) {
    final trimmed = _titleController.text.trim();
    appState.updateEntry(entry.id, title: trimmed.isEmpty ? 'Feeling ${entry.mood.label}' : trimmed);
    setState(() => _editingTitle = false);
  }

  Future<void> _addPhoto(BuildContext context, AppState appState, JournalEntry entry) async {
    // Belt-and-suspenders: the "Add More" tile is already hidden once the
    // cap is hit, so this is only reachable if something else ever calls
    // _addPhoto directly.
    if (entry.photos.length >= JournalEntry.maxPhotos) {
      showAppSnackBar(context, 'Up to ${JournalEntry.maxPhotos} photos per entry');
      return;
    }
    final source = await showPhotoSourceSheet(context);
    if (source == null || !context.mounted) return;
    final photo = await pickPhotoAsBase64(source);
    if (photo != null) appState.addPhoto(entry.id, photo);
  }

  Future<void> _recordVoiceNote(BuildContext context, AppState appState, JournalEntry entry) async {
    final voiceNote = await showVoiceRecorderSheet(context);
    if (voiceNote != null) appState.setVoiceNote(entry.id, voiceNote);
  }

  Future<void> _pickMood(BuildContext context, AppState appState, JournalEntry entry) async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in Mood.values)
              ListTile(
                leading: Text(m.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(m.label),
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (mood != null && mood != entry.mood) {
      appState.updateEntry(entry.id, mood: mood);
    }
  }

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final label = isToday ? 'Today' : DateFormat.yMMMd().format(dt);
    return '$label, ${DateFormat('h:mm a').format(dt)}';
  }

  void _shareEntry(JournalEntry entry) {
    final buffer = StringBuffer('${entry.mood.emoji} ${entry.title}\n${_relativeDate(entry.dateTime)}');
    if (entry.text.isNotEmpty) buffer.write('\n\n${entry.text}');
    if (entry.labels.isNotEmpty) buffer.write('\n\nTags: ${entry.labels.join(', ')}');
    Share.share(buffer.toString(), subject: entry.title);
  }

  // Same daily-cap check as the Deleted Entries list's own Restore
  // button — restoring shouldn't be able to push a day past its
  // maxDailyEntries limit any more than creating a new entry can.
  void _restore(BuildContext context, AppState appState, JournalEntry entry) {
    if (appState.hasReachedDailyCap(entry.dateTime)) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Can't restore"),
          content: Text(
              "${DateFormat.yMMMMd().format(entry.dateTime)} already has ${AppState.maxDailyEntries} entries — delete one from that day before restoring this."),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    appState.restoreEntry(entry.id);
    showAppSnackBar(context, 'Entry restored');
    Navigator.of(context).pop();
  }

  // Same confirm/wording as the Deleted Entries list's own "Delete
  // Forever" button — this just offers the identical action without
  // making the user go back to History first.
  Future<void> _confirmDeleteForever(BuildContext context, AppState appState, JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content: Text('"${entry.title}" will be permanently removed. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      appState.permanentlyDeleteEntry(entry.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final entry = _findEntry(appState);
        final scheme = Theme.of(context).colorScheme;
        final canEdit = entry != null && !entry.isDeleted;
        // If a Writing Theme was picked while composing this entry, its
        // cards stay tinted that color instead of reverting to plain
        // white/neutral once saved — same alphaBlend the composer itself
        // uses, so the detail view looks like a continuation of how it
        // was actually written.
        final themeColor =
            entry?.themeName == null ? null : resolveJournalThemeColor(entry!.themeName!, scheme.brightness);
        final cardColor = themeColor == null
            ? scheme.surfaceContainerLowest
            : Color.alphaBlend(themeColor.withValues(alpha: 0.35), scheme.surfaceContainerLowest);
        // Tag chips need their own contrast fix in light mode: a plain
        // grey chip barely reads against a white/near-white ("White"
        // theme, or no theme at all) card, so that case keeps grey, but
        // any actual color tint already gives the card its own hue, so
        // the chip flips to plain white there instead — same swap the
        // composer's tag input and content box use. Dark mode is
        // untouched, since its own colors already contrast fine.
        final isWhiteTheme = entry?.themeName == null || entry?.themeName == 'White';
        final tagChipColor =
            scheme.brightness == Brightness.dark ? null : (isWhiteTheme ? scheme.surfaceContainerHigh : Colors.white);

        if (entry == null) {
          // Deleted permanently (e.g. via History) while this screen was
          // open — nothing left to show.
          return Scaffold(
            appBar: AppBar(leading: BackButton(color: scheme.onSurfaceVariant)),
            body: Center(
              child: Text('This entry no longer exists.', style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Color.alphaBlend(entry.mood.swatch.withValues(alpha: 0.15), scheme.surface),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: BackButton(color: scheme.onSurface),
            // Share is the only thing this menu offers — no point showing
            // an empty ⋮ for a deleted entry, which isn't shareable.
            actions: [
              if (canEdit)
                PopupMenuButton<void>(
                  icon: Icon(Icons.more_vert, color: scheme.onSurface),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _shareEntry(entry),
                      child: const Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          SizedBox(width: 12),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Center(
                child: InkWell(
                  onTap: canEdit ? () => _pickMood(context, appState, entry) : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: entry.mood.swatch, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.mood.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        // The mood's own label, not entry.title — title is
                        // now an independently editable headline (below)
                        // and may not have anything to do with the mood.
                        Text('Feeling ${entry.mood.label}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: entry.mood.onSwatch)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                // The title is only editable while the entry itself is in
                // edit mode (the pencil FAB below) — outside of that it's
                // plain read-only text, no pencil, matching how the body
                // text and photo-delete buttons are also edit-mode-only.
                child: !_editingText
                    ? Text(entry.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface))
                    : _editingTitle
                        ? TapRegion(
                            // Tapping outside still auto-saves (same as
                            // the tag "+" field below), but there's also
                            // an explicit tick now — tap-outside alone
                            // isn't an obvious "save" action to everyone.
                            onTapOutside: (_) => _saveTitle(appState, entry),
                            child: SizedBox(
                              width: 280,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: TextField(
                                      controller: _titleController,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      maxLength: _maxTitleLength,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText: 'Title your entry...',
                                        counterText: '',
                                      ),
                                      onSubmitted: (_) => _saveTitle(appState, entry),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _saveTitle(appState, entry),
                                    customBorder: const CircleBorder(),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.check_circle, size: 20, color: scheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () => _startEditingTitle(entry),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(entry.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface)),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit, size: 16, color: scheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(_relativeDate(entry.dateTime), style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              if (_editingText) ...[
                const SizedBox(height: 16),
                Text('Writing Theme',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final themeEntry in journalThemes.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ThemeSwatch(
                          color: resolveJournalThemeColor(themeEntry.key, scheme.brightness),
                          selected: entry.themeName == themeEntry.key,
                          onTap: () => appState.updateEntry(entry.id, themeName: themeEntry.key),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              // Its own section, above the written-text card rather than
              // buried inside it — a voice note is its own kind of
              // content, not an afterthought tacked onto the text.
              // Skipped entirely outside edit mode with nothing recorded
              // yet, same reasoning as the Moments Captured card below.
              if (entry.voiceNote != null || _editingText) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
                  ),
                  child: entry.voiceNote != null
                      ? VoiceNotePlayer(
                          base64Audio: entry.voiceNote!,
                          // Delete-only, no direct re-record — a voice
                          // note only ever gets recorded once; to replace
                          // it, delete this one first and use "Add Voice
                          // Note" to record a fresh take. Only offered in
                          // edit mode, same gating as the title, photos,
                          // and tags.
                          onDelete: _editingText ? () => appState.removeVoiceNote(entry.id) : null,
                        )
                      : FilledButton.icon(
                          // Solid, not outlined — an outlined button here
                          // just let the card's Writing Theme tint show
                          // straight through it instead of standing out
                          // as its own control.
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => _recordVoiceNote(context, appState, entry),
                          icon: const Icon(Icons.mic, size: 18),
                          label: const Text('Add Voice Note'),
                        ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tag in entry.labels)
                          _RemovableTagChip(
                            label: tag,
                            onRemove: () => appState.removeLabel(entry.id, tag),
                            // Same edit-mode gating as the title, photos,
                            // and voice note — _editingText can only be
                            // true when canEdit already is, so this
                            // covers the deleted-entry read-only case too.
                            showRemove: _editingText,
                            color: tagChipColor,
                          ),
                        // Hidden once at the tag cap, rather than still
                        // inviting a tap that would just add past it.
                        if (_editingText && entry.labels.length < _maxTags)
                          _AddTagButton(
                            onAdd: (tag) {
                              if (entry.labels.length >= _maxTags) {
                                showAppSnackBar(context, 'Up to $_maxTags tags per entry');
                                return;
                              }
                              appState.addLabel(entry.id, tag);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _editingText
                        ? TextField(
                            controller: _textController,
                            autofocus: true,
                            maxLines: null,
                            minLines: 6,
                            maxLength: _maxTextLength,
                            style: TextStyle(fontSize: 16, height: 1.6, color: scheme.onSurface),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write your thoughts here...',
                              counterText: '',
                              // Otherwise this falls back to the app-wide
                              // input fill (a flat grey), which ignores
                              // the entry's Writing Theme entirely — same
                              // white/grey swap as the tag chips above.
                              filled: true,
                              fillColor: tagChipColor,
                            ),
                          )
                        : Text(
                            entry.text.isEmpty ? 'No written reflection for this entry yet.' : entry.text,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: entry.text.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
                              fontStyle: entry.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                    if (_editingText) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _textController,
                          builder: (context, value, _) => Text(
                            '${value.text.length} / $_maxTextLength',
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Its own card, not crammed into the one above — a 3-per-row
              // photo grid next to the written text and tags made that
              // first card feel cramped, especially with several photos.
              // Skipped entirely in view mode with no photos yet — an
              // empty "Moments Captured" card with no way to add one
              // would just be dead weight.
              if (entry.photos.isNotEmpty || _editingText) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // The "x/6" count is only meaningful once you can
                        // actually do something about it — same edit-mode
                        // gating as the "Add More" tile and delete
                        // buttons below.
                        !_editingText || entry.photos.isEmpty
                            ? 'Moments Captured'
                            : 'Moments Captured · ${entry.photos.length}/${JournalEntry.maxPhotos}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      // Fixed 3-per-row grid rather than Wrap — Wrap would
                      // let the row hold a different number of tiles
                      // depending on screen width, which looks
                      // inconsistent entry to entry; a real grid keeps
                      // rows of 3 always.
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                        children: [
                          for (var i = 0; i < entry.photos.length; i++)
                            PhotoTile(
                              base64Photo: entry.photos[i],
                              onRemove: () => appState.removePhoto(entry.id, i),
                              size: double.infinity,
                              // Hidden until the entry is put into edit
                              // mode — a plain view of an entry shouldn't
                              // be cluttered with delete affordances.
                              showDeleteButton: _editingText,
                            ),
                          if (_editingText && entry.photos.length < JournalEntry.maxPhotos)
                            AddPhotoTile(
                              label: entry.photos.isEmpty ? 'Add Photo' : 'Add More',
                              onTap: () => _addPhoto(context, appState, entry),
                              size: double.infinity,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (!canEdit) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _restore(context, appState, entry),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Restore'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.errorContainer),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _confirmDeleteForever(context, appState, entry),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete Forever'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          // No edit FAB at all for a deleted entry — it's view-only until
          // restored.
          floatingActionButton: !canEdit
              ? null
              : _editingText
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'entry-cancel-${entry.id}',
                          mini: true,
                          backgroundColor: scheme.surfaceContainerHigh,
                          foregroundColor: scheme.onSurfaceVariant,
                          tooltip: 'Cancel',
                          onPressed: () => _cancelEditingText(appState, entry),
                          child: const Icon(Icons.close),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          heroTag: 'entry-save-${entry.id}',
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          tooltip: 'Save',
                          onPressed: () => _saveText(context, appState, entry),
                          child: const Icon(Icons.save),
                        ),
                      ],
                    )
                  : FloatingActionButton(
                      heroTag: 'entry-edit-${entry.id}',
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      tooltip: 'Edit',
                      onPressed: () => _startEditingText(entry),
                      child: const Icon(Icons.edit),
                    ),
        );
      },
    );
  }
}

/// A tag chip with an always-visible ✕ to remove it — no long-press or
/// confirm dialog needed since the ✕ is already an explicit, deliberate
/// tap target (unlike e.g. swipe-to-delete on a whole entry, which is
/// riskier to trigger by accident and still gets a confirm dialog).
class _RemovableTagChip extends StatelessWidget {
  const _RemovableTagChip({required this.label, required this.onRemove, this.showRemove = true, this.color});
  final String label;
  final VoidCallback onRemove;

  /// Same read-only gating as [PhotoTile.showDeleteButton] — off for a
  /// deleted entry being viewed, so its tags read as plain chips.
  final bool showRemove;

  /// Background override so the chip stays visible against the card's own
  /// Writing Theme tint — see EntryDetailScreen's _tagChipColor. Falls back
  /// to the plain neutral chip color when not given.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: 14, right: showRemove ? 6 : 14, top: 6, bottom: 6),
      decoration: BoxDecoration(color: color ?? scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          if (showRemove)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dashed "+" circle that turns into an inline text field for adding
/// a new custom tag. (Flutter has no built-in dashed border, and pulling
/// in a package for one felt like overkill for a single circle — this
/// uses a plain solid outline instead; visually close, functionally
/// identical.)
class _AddTagButton extends StatefulWidget {
  const _AddTagButton({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<_AddTagButton> createState() => _AddTagButtonState();
}

class _AddTagButtonState extends State<_AddTagButton> {
  // Matches Journal composer's tag length cap — see the comment there.
  static const _maxTagLength = 15;

  bool _adding = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    widget.onAdd(_controller.text);
    setState(() {
      _adding = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_adding) {
      return InkWell(
        onTap: () => setState(() => _adding = true),
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.outlineVariant)),
          child: Icon(Icons.add, size: 16, color: scheme.outlineVariant),
        ),
      );
    }
    return TapRegion(
      // Same auto-save-on-tap-outside as the main text editor — tapping
      // elsewhere confirms whatever's typed (or just closes back to the
      // "+" if nothing was typed; addLabel no-ops on blank input).
      onTapOutside: (_) => _confirm(),
      child: SizedBox(
        width: 150,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: _maxTagLength,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'New tag',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  counterText: '',
                ),
                onSubmitted: (_) => _confirm(),
              ),
            ),
            InkWell(
              onTap: _confirm,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.check_circle, size: 20, color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
