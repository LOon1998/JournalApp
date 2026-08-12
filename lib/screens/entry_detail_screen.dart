import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../services/media_capture.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/voice_note_player.dart';
import '../widgets/voice_recorder_sheet.dart';

/// Full-page detail/edit view for a single entry — reached by tapping an
/// entry on the Journal timeline or a Calendar day-detail card (as
/// opposed to the small inline expand/collapse chevron each row already
/// has, which stays for a quick peek without leaving the list).
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

  bool _editingText = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
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
    showAppSnackBar(context, 'Entry saved');
    setState(() => _editingText = false);
  }

  void _cancelEditingText(JournalEntry entry) {
    // The underlying entry was never touched by editing — only the draft
    // in _textController was — so "cancelling" just means throwing that
    // draft away and dropping out of edit mode; nothing to undo on the
    // AppState side.
    setState(() {
      _editingText = false;
      _textController.text = entry.text;
    });
  }

  Future<void> _addPhoto(BuildContext context, AppState appState, JournalEntry entry) async {
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
                  onTap: () => _pickMood(context, appState, entry),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: entry.mood.swatch, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.mood.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(entry.title,
                            style: TextStyle(fontWeight: FontWeight.w700, color: entry.mood.onSwatch)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(_relativeDate(entry.dateTime), style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 20),
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
                          ),
                        _AddTagButton(onAdd: (tag) => appState.addLabel(entry.id, tag)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (var i = 0; i < entry.photos.length; i++)
                          _PhotoThumbnail(
                            base64Photo: entry.photos[i],
                            onRemove: () => appState.removePhoto(entry.id, i),
                          ),
                        InkWell(
                          onTap: () => _addPhoto(context, appState, entry),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Icon(Icons.add_a_photo_outlined, size: 20, color: scheme.outlineVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (entry.voiceNote != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VoiceNotePlayer(base64Audio: entry.voiceNote!),
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
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _recordVoiceNote(context, appState, entry),
                        icon: const Icon(Icons.mic, size: 18),
                        label: const Text('Add Voice Note'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _editingText
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

/// A photo thumbnail — tap to view full-screen, tap the ✕ to remove.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.base64Photo, required this.onRemove});
  final String base64Photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64Photo);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tag chip with an always-visible ✕ to remove it — no long-press or
/// confirm dialog needed since the ✕ is already an explicit, deliberate
/// tap target (unlike e.g. swipe-to-delete on a whole entry, which is
/// riskier to trigger by accident and still gets a confirm dialog).
class _RemovableTagChip extends StatelessWidget {
  const _RemovableTagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
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
