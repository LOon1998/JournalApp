import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../services/media_capture.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/photo_tile.dart';
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
  static const _maxTitleLength = 60;

  bool _editingText = false;
  final _textController = TextEditingController();

  bool _editingTitle = false;
  final _titleController = TextEditingController();

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
    setState(() => _editingText = true);
  }

  void _saveText(BuildContext context, AppState appState, JournalEntry entry) {
    appState.updateEntry(entry.id, text: _textController.text.trim());
    // Leaving edit mode retires the title editor too, if it was left
    // mid-edit — save it rather than silently abandoning it.
    if (_editingTitle) _saveTitle(appState, entry);
    showAppSnackBar(context, 'Entry saved');
    setState(() => _editingText = false);
  }

  void _cancelEditingText(JournalEntry entry) {
    // The underlying entry was never touched by editing — only the drafts
    // in _textController and _titleController were — so "cancelling" just
    // means throwing those drafts away and dropping out of edit mode;
    // nothing to undo on the AppState side.
    setState(() {
      _editingText = false;
      _textController.text = entry.text;
      _editingTitle = false;
      _titleController.text = entry.title;
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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final entry = _findEntry(appState);
        final scheme = Theme.of(context).colorScheme;
        final canEdit = entry != null && !entry.isDeleted;

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
            actions: [
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
                                            ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
                                        overflow: TextOverflow.ellipsis),
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
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
                  ),
                  child: entry.voiceNote != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VoiceNotePlayer(base64Audio: entry.voiceNote!),
                            // Re-record/delete only once the entry itself
                            // is in edit mode — same gating as the title,
                            // photos, and tags.
                            if (_editingText) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _recordVoiceNote(context, appState, entry),
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.mic, size: 20, color: scheme.onSurfaceVariant),
                                ),
                              ),
                              InkWell(
                                onTap: () => appState.removeVoiceNote(entry.id),
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline, size: 20, color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ],
                        )
                      : OutlinedButton.icon(
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
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _editingText
                        ? TextField(
                            controller: _textController,
                            autofocus: true,
                            maxLines: null,
                            minLines: 6,
                            maxLength: _maxTextLength,
                            style: TextStyle(fontSize: 16, height: 1.6, color: scheme.onSurface),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write your thoughts here...',
                              counterText: '',
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
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tag in entry.labels)
                          _RemovableTagChip(
                            label: tag,
                            onRemove: () => appState.removeLabel(entry.id, tag),
                            showRemove: canEdit,
                          ),
                        if (canEdit) _AddTagButton(onAdd: (tag) => appState.addLabel(entry.id, tag)),
                      ],
                    ),
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
                    color: scheme.surfaceContainerLowest,
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
                          onPressed: () => _cancelEditingText(entry),
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
  const _RemovableTagChip({required this.label, required this.onRemove, this.showRemove = true});
  final String label;
  final VoidCallback onRemove;

  /// Same read-only gating as [PhotoTile.showDeleteButton] — off for a
  /// deleted entry being viewed, so its tags read as plain chips.
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: 14, right: showRemove ? 6 : 14, top: 6, bottom: 6),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
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
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'New tag',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
