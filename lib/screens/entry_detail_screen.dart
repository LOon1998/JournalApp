import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement, rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:share_plus/share_plus.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/app_lock_service.dart';
import '../services/media_capture.dart';
import '../theme/activity_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/mood_emoji.dart';
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

  // Lets the PopScope handler below flush any tag still typed but not yet
  // confirmed in the "+" field — see that handler's own doc.
  final _addTagKey = GlobalKey<_AddTagButtonState>();

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
  Mood? _moodSnapshot;

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
    _moodSnapshot = entry.mood;
    setState(() => _editingText = true);
  }

  void _saveText(BuildContext context, AppState appState, JournalEntry entry) {
    appState.updateEntry(entry.id, text: _textController.text.trim());
    // Leaving edit mode retires the title editor too, if it was left
    // mid-edit — save it rather than silently abandoning it.
    if (_editingTitle) _saveTitle(appState, entry);
    showAppSnackBar(context, AppLocalizations.of(context)!.entrySavedSnackbar);
    setState(() {
      _editingText = false;
      _photosSnapshot = null;
      _tagsSnapshot = null;
      _activitiesSnapshot = null;
      _voiceNoteSnapshot = null;
      _titleSnapshot = null;
      _themeNameSnapshot = null;
      _moodSnapshot = null;
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
      appState.updateEntry(
        entry.id,
        title: _titleSnapshot!,
        mood: _moodSnapshot,
      );
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
      _moodSnapshot = null;
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
    appState.updateEntry(
      entry.id,
      title: trimmed.isEmpty ? 'Feeling ${entry.mood.label}' : trimmed,
    );
    setState(() => _editingTitle = false);
  }

  Future<void> _addPhoto(
    BuildContext context,
    AppState appState,
    JournalEntry entry,
  ) async {
    // Belt-and-suspenders: the "Add More" tile is already hidden once the
    // cap is hit, so this is only reachable if something else ever calls
    // _addPhoto directly.
    if (entry.photos.length >= JournalEntry.maxPhotos) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.journalPhotoCap(JournalEntry.maxPhotos),
      );
      return;
    }
    final source = await showPhotoSourceSheet(context);
    if (source == null || !context.mounted) return;
    final photo = await pickPhotoAsBase64(source);
    if (photo != null) appState.addPhoto(entry.id, photo);
  }

  Future<void> _recordVoiceNote(
    BuildContext context,
    AppState appState,
    JournalEntry entry,
  ) async {
    final voiceNote = await showVoiceRecorderSheet(context);
    if (voiceNote == null || !context.mounted) return;
    appState.setVoiceNote(entry.id, voiceNote);
  }

  Future<void> _pickMood(
    BuildContext context,
    AppState appState,
    JournalEntry entry,
  ) async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in Mood.values)
              ListTile(
                leading: MoodEmoji(mood: m, size: 22),
                title: Text(moodLabel(context, m)),
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
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final locale = Localizations.localeOf(context).toString();
    final label = isToday
        ? AppLocalizations.of(context)!.entryToday
        : DateFormat.yMMMd(locale).format(dt);
    return '$label, ${DateFormat('h:mm a', locale).format(dt)}';
  }

  void _shareEntryAsText(JournalEntry entry) {
    final title = entryDisplayTitle(context, entry);
    final buffer = StringBuffer(
      '${entry.mood.emoji} $title\n${_relativeDate(entry.dateTime)}',
    );
    if (entry.text.isNotEmpty) buffer.write('\n\n${entry.text}');
    if (entry.labels.isNotEmpty) {
      buffer.write(
        '\n\n${AppLocalizations.of(context)!.entryShareTagsPrefix}${entry.labels.join(', ')}',
      );
    }
    // See _shareEntry's own ExternalActivityGuard.begin() call for why.
    ExternalActivityGuard.begin();
    Share.share(
      buffer.toString(),
      subject: title,
    ).whenComplete(ExternalActivityGuard.end);
  }

  /// Shares this entry as a real, selectable-text, paginating PDF — mood,
  /// title, date, tags, body text, and photos, in that order. Not a
  /// screenshot of the screen: a PDF is expected to paginate properly for
  /// a long entry and stay text-searchable, neither of which a raster
  /// image can do. No voice note is attached — audio can't go *inside* a
  /// static document, and unlike the entry's own on-screen player, a PDF
  /// has no way to represent "there's audio here" that's actually useful
  /// to whoever receives it. Falls back to a plain-text share if the PDF
  /// itself fails to generate, or if file-sharing isn't actually
  /// supported here (some desktop browsers don't implement the Web Share
  /// API's file-sharing extension) — better than the Share button
  /// silently doing nothing.
  Future<void> _shareEntry(JournalEntry entry) async {
    final title = entryDisplayTitle(context, entry);
    final dateLabel = _relativeDate(entry.dateTime);
    // Captured here, from this method's own Flutter BuildContext — not
    // read inside pw.MultiPage's build callback below, whose own
    // `context` parameter shadows this one with an unrelated pdf-package
    // Context type that moodLabel can't accept.
    final moodLabelText = moodLabel(context, entry.mood);
    // "Feeling {mood}", not just the bare mood word — matches the
    // on-screen mood pill's own text (see entryFeelingMood's other use,
    // in this same file's build() below).
    final moodPillText = AppLocalizations.of(context)!.entryFeelingMood(moodLabelText);
    // Same reasoning — the photos card's own header, missing from the PDF
    // export entirely before this (the on-screen "Moments Captured" card
    // has one; this card just went straight into the photo grid with
    // nothing labeling what it was).
    final momentsCapturedText = AppLocalizations.of(context)!.entryMomentsCaptured;
    // Same reasoning again — the on-screen tag chips run each label
    // through activityLabel to translate the fixed presets (stored as
    // plain English keys like 'Work' regardless of language, same as
    // Mood's own enum names) into the current language's own word for
    // it; a custom, freely-typed tag just passes through unchanged
    // either way. The PDF export skipped this translation step
    // entirely, so a preset tag exported in Chinese always came out as
    // its raw English key no matter what language the rest of the
    // export (and the entry itself) was actually in.
    final translatedLabels = [for (final tag in entry.labels) activityLabel(context, tag)];
    // The PDF page's own background — the same *mood* tint the on-screen
    // whole-screen background carries (screenBackground, built from
    // entry.mood.swatch, not the Writing Theme), blended lightly into
    // white (paper has no dark surface to blend into the way the app's
    // own screen does). Got this backwards in an earlier version — the
    // Writing Theme color went on the page and the cards stayed plain
    // white, the reverse of how the on-screen entry actually splits these
    // two colors: mood tints the *page*, Writing Theme tints the *cards*
    // (see pdfCardColor below) — so a themed, moodful entry didn't export
    // looking like the entry it actually was.
    final pdfBackgroundBlend = Color.alphaBlend(
      entry.mood.swatch.withValues(alpha: 0.15),
      Colors.white,
    );
    final pdfBackgroundColor = PdfColor(
      pdfBackgroundBlend.r,
      pdfBackgroundBlend.g,
      pdfBackgroundBlend.b,
    );
    // The cards' own background — the Writing Theme tint the on-screen
    // cards carry (cardColor), not the page. A null themeName resolves to
    // 'White' (see resolveJournalThemeColor's own doc), which blended
    // into white stays white — no visible change from a plain white card
    // for an entry that never had a theme set.
    final pdfThemeColor = resolveJournalThemeColor(
      entry.themeName ?? 'White',
      Brightness.light,
    );
    final pdfCardBlend = Color.alphaBlend(
      pdfThemeColor.withValues(alpha: 0.35),
      Colors.white,
    );
    final pdfCardColor = PdfColor(
      pdfCardBlend.r,
      pdfCardBlend.g,
      pdfCardBlend.b,
    );
    // Same white/grey swap the on-screen tag chips make (tagChipColor) —
    // plain grey barely reads against a white/near-white card (a null
    // theme, or 'White' itself), but any actual color tint already gives
    // the card its own hue, so the chip needs to flip to white there
    // instead to still stand out. A fixed grey regardless of theme (what
    // this used to be) is exactly the same contrast problem the on-screen
    // chips solved for.
    final pdfIsWhiteTheme = entry.themeName == null || entry.themeName == 'White';
    final pdfTagChipColor = pdfIsWhiteTheme ? PdfColors.grey200 : PdfColors.white;
    // Always exactly 3 photos per row, matching the on-screen Moments
    // Captured card's own fixed-3-column GridView (not a Wrap left to
    // fit however many happen to fit at a hardcoded tile size — that's
    // what left this at 2 per row before, since 3 real photos side by
    // side at a fixed 160pt each plus spacing didn't actually fit the
    // card's available width). Computed from the same page/margin/card-
    // padding constants used to build this card, rather than hardcoded,
    // so it stays correct if any of those ever change.
    const pdfPageMargin = 32.0;
    const pdfCardPadding = 20.0;
    const pdfPhotoSpacing = 10.0;
    final pdfCardContentWidth = PdfPageFormat.a4.width - pdfPageMargin * 2 - pdfCardPadding * 2;
    final photoTileSize = (pdfCardContentWidth - pdfPhotoSpacing * 2) / 3;
    final moodSwatch = PdfColor(
      entry.mood.swatch.r,
      entry.mood.swatch.g,
      entry.mood.swatch.b,
    );
    final moodOnSwatch = PdfColor(
      entry.mood.onSwatch.r,
      entry.mood.onSwatch.g,
      entry.mood.onSwatch.b,
    );
    try {
      // pdf's own built-in fonts are Latin-only (Base14/Helvetica) — a
      // Chinese title/tag/body silently rendered as blank boxes without
      // this, since this app is bilingual and any entry could contain
      // either language, or both.
      final baseFont = await PdfGoogleFonts.notoSansSCRegular();
      final boldFont = await PdfGoogleFonts.notoSansSCBold();
      // A dedicated emoji glyph font — NotoSansSC above (or any plain text
      // font) has no emoji glyphs at all, which is why entry.mood.emoji
      // used to render as a broken tofu/missing-glyph box instead of the
      // actual face. Added as a *fallback*, not the base font — the pdf
      // package's own text layout already checks, per character, whether
      // the primary font has a glyph for it and falls through to the next
      // font in the list if not, so a single pw.Text mixing an emoji and
      // regular words (see the mood pill below) just works without
      // needing to manually split it into two separately-styled Text
      // widgets. This is the plain outline Noto Emoji, not the full-color
      // Noto Color Emoji — the pdf package's text renderer draws vector
      // glyph outlines, not layered color bitmaps, so a color-emoji font
      // would fail to render here the same way the raw glyph did before.
      final emojiFont = await PdfGoogleFonts.notoEmojiRegular();
      // Same icon+wordmark image the About screen itself uses (see its own
      // doc) — branding the export as Moodlet's own, matching the
      // reference design's logo header.
      final logoBytes = await rootBundle.load('assets/branding/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      if (!mounted) return;
      final doc = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          fontFallback: [emojiFont],
        ),
      );
      final photoImages = [
        for (final base64Photo in entry.photos)
          pw.MemoryImage(base64Decode(base64Photo)),
      ];
      doc.addPage(
        pw.MultiPage(
          // pageFormat/margin move in here (rather than staying as
          // MultiPage's own top-level params) because pw.Page's
          // constructor asserts against setting both pageTheme and those
          // other settings at once — buildBackground below is only
          // reachable through pageTheme.
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            // True edge-to-edge bleed (ignoreMargins: true) — the jagged,
            // self-intersecting corruption a real device reported here
            // turned out to have nothing to do with full-bleed painting
            // (an earlier fix briefly bounded this to the margin box on
            // that theory, but the corruption was later reproduced with
            // this exact full-bleed setup too, and confirmed gone once
            // the real cause — an unclamped, oversized corner radius
            // elsewhere on the page — was fixed instead; see the mood
            // pill's own borderRadius comment below).
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: pdfBackgroundColor),
            ),
            // The logo itself lives here, not in the page's own content
            // list below — that list is laid out inside the page's 32pt
            // margin, so a plain top-of-content placement always sat that
            // same 32pt down from the actual page edge, further from the
            // corner than wanted. buildForeground, like buildBackground
            // above, paints across the *entire* page (ignoreMargins:
            // true) on top of the regular content, letting this sit right
            // at the true top-right corner (just a small 16pt pad of its
            // own so it isn't flush against the trimmed edge) regardless
            // of where the margin puts everything else.
            buildForeground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 16, right: 16),
                child: pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.Image(logoImage, height: 20),
                ),
              ),
            ),
          ),
          // Rounded white cards floating on the tinted page background,
          // matching the app's own on-screen card layout instead of the
          // previous flat, uncarded arrangement — per the reference design.
          // No shadow on these (unlike the app's own FloatingCard) — kept
          // deliberately simple after the full-bleed background trouble
          // above; a plain flat card is the lower-risk choice until that's
          // confirmed resolved.
          build: (context) => [
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // The actual mood emoji, in the same swatch-colored pill
                  // as the on-screen mood badge — see emojiFont above for
                  // what makes this glyph render properly here now instead
                  // of the broken box it used to.
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: moodSwatch,
                      // A modest rounding, not a full pill/stadium shape —
                      // also sidesteps the same corruption an extreme,
                      // unclamped radius (circular(999)) caused here
                      // before: this pdf package doesn't clamp a corner
                      // radius that exceeds the box's own half-height the
                      // way Flutter's own BorderRadius does, and that was
                      // found (through direct testing — reproduced,
                      // isolated, and confirmed fixed) to corrupt the
                      // rendering of *later* rounded-corner shapes on the
                      // same page into a jagged, self-intersecting mess,
                      // not just its own.
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      '${entry.mood.emoji} $moodPillText',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: moodOnSwatch),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
            ),
            // No voice-note card — explicitly asked to drop it regardless
            // of whether an entry has one, not just when it doesn't. A
            // real player can't go *inside* a static PDF the way it can
            // on-screen anyway, so there was never anything actually
            // playable here to justify the card either way.
            if (entry.labels.isNotEmpty || entry.text.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: pdfCardColor,
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (entry.labels.isNotEmpty)
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in translatedLabels)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: pw.BoxDecoration(
                                color: pdfTagChipColor,
                                borderRadius: pw.BorderRadius.circular(12),
                              ),
                              child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    if (entry.labels.isNotEmpty && entry.text.isNotEmpty) pw.SizedBox(height: 16),
                    if (entry.text.isNotEmpty)
                      pw.Text(entry.text, style: const pw.TextStyle(fontSize: 13, lineSpacing: 3)),
                  ],
                ),
              ),
            ],
            if (photoImages.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: pdfCardColor,
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      momentsCapturedText,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final image in photoImages)
                          pw.ClipRRect(
                            horizontalRadius: 10,
                            verticalRadius: 10,
                            child: pw.Image(image, width: photoTileSize, height: photoTileSize, fit: pw.BoxFit.cover),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
      final bytes = await doc.save();
      if (!mounted) return;
      final file = XFile.fromData(
        bytes,
        name: 'lumina-entry.pdf',
        mimeType: 'application/pdf',
      );
      // The native share sheet backgrounds this app the same way
      // switching away to another app does — see ExternalActivityGuard's
      // own doc for why this stops that from being mistaken for actually
      // leaving and re-locking the app (if Pattern Lock is on) the moment
      // it returns.
      ExternalActivityGuard.begin();
      try {
        await Share.shareXFiles([file], subject: title);
      } finally {
        ExternalActivityGuard.end();
      }
    } catch (_) {
      if (!mounted) return;
      _shareEntryAsText(entry);
    }
  }

  // Same daily-cap check as the Deleted Entries list's own Restore
  // button — restoring shouldn't be able to push a day past its
  // maxDailyEntries limit any more than creating a new entry can.
  void _restore(BuildContext context, AppState appState, JournalEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    if (appState.hasReachedDailyCap(entry.dateTime)) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deletedEntriesCantRestoreTitle),
          content: Text(
            l10n.deletedEntriesCantRestoreBody(
              DateFormat.yMMMMd(
                Localizations.localeOf(context).toString(),
              ).format(entry.dateTime),
              AppState.maxDailyEntries,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionOk),
            ),
          ],
        ),
      );
      return;
    }
    appState.restoreEntry(entry.id);
    showAppSnackBar(context, l10n.entryRestoredSnackbar);
    Navigator.of(context).pop();
  }

  // Same confirm/wording as the Deleted Entries list's own "Delete
  // Forever" button — this just offers the identical action without
  // making the user go back to History first.
  Future<void> _confirmDeleteForever(
    BuildContext context,
    AppState appState,
    JournalEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletedEntriesDeleteForeverConfirmTitle),
        content: Text(
          l10n.deletedEntriesDeleteForeverConfirmBody(
            entryDisplayTitle(context, entry),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
    // A plain Builder (not AnimatedBuilder) — this screen already rebuilds
    // automatically whenever appState changes, via the AppStateScope.of
    // dependency above; a second, independent listener on the same
    // notifier was what caused an intermittent "check that it really is
    // our descendant" InheritedElement assertion (see main.dart's
    // _SignedInMaterialApp for the full explanation — same underlying
    // cause, fixed the same way here).
    return PopScope<void>(
      // Blocks a plain pop — a misclick on the system/app-bar back button,
      // or the Android back gesture — while body-text edit mode is still
      // open. Without this, that pop went straight through: the typed
      // text (which only ever lives in _textController until Save is
      // tapped) was silently lost, while photos, tags, the title, voice
      // note, and mood — all of which commit to the entry immediately as
      // soon as they're touched, see _startEditingText's own doc — stayed
      // changed regardless. That's a half-saved entry, not a cleanly
      // saved or cleanly discarded one; onPopInvokedWithResult below saves
      // properly (the same path the Save button itself uses) before
      // letting the pop finish, so a misclick keeps the work instead of
      // quietly losing half of it.
      canPop: !_editingText,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final entry = _findEntry(appState);
        if (entry == null) return;
        // Flushes a tag still typed but not yet explicitly confirmed in
        // the "+" field first — that field's own text lives entirely in
        // its own local controller, outside anything _saveText below
        // touches, so without this a tag typed right before a misclick
        // back would've been silently dropped the same way the body text
        // itself used to be.
        _addTagKey.currentState?.confirmPendingTag();
        _saveText(context, appState, entry);
        Navigator.of(context).pop();
      },
      child: Builder(
        builder: (context) {
          final entry = _findEntry(appState);
          final scheme = Theme.of(context).colorScheme;
          final l10n = AppLocalizations.of(context)!;
          final canEdit = entry != null && !entry.isDeleted;
          // If a Writing Theme was picked while composing this entry, its
          // cards stay tinted that color instead of reverting to plain
          // white/neutral once saved — same alphaBlend the composer itself
          // uses, so the detail view looks like a continuation of how it
          // was actually written.
          final themeColor = entry?.themeName == null
              ? null
              : resolveJournalThemeColor(entry!.themeName!, scheme.brightness);
          final cardColor = themeColor == null
              ? scheme.surfaceContainerLowest
              : Color.alphaBlend(
                  themeColor.withValues(alpha: 0.35),
                  scheme.surfaceContainerLowest,
                );
          // Tag chips need their own contrast fix in light mode: a plain
          // grey chip barely reads against a white/near-white ("White"
          // theme, or no theme at all) card, so that case keeps grey, but
          // any actual color tint already gives the card its own hue, so
          // the chip flips to plain white there instead — same swap the
          // composer's tag input and content box use. Dark mode is
          // untouched, since its own colors already contrast fine.
          final isWhiteTheme =
              entry?.themeName == null || entry?.themeName == 'White';
          final tagChipColor = scheme.brightness == Brightness.dark
              ? null
              : (isWhiteTheme ? scheme.surfaceContainerHigh : Colors.white);

          if (entry == null) {
            // Deleted permanently (e.g. via History) while this screen was
            // open — nothing left to show.
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(color: scheme.onSurfaceVariant),
              ),
              body: Center(
                child: Text(
                  l10n.entryNoLongerExists,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            );
          }

          final screenBackground = Color.alphaBlend(
            entry.mood.swatch.withValues(alpha: 0.15),
            scheme.surface,
          );

          return Scaffold(
            backgroundColor: screenBackground,
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
                        child: Row(
                          children: [
                            const Icon(Icons.share_outlined, size: 18),
                            const SizedBox(width: 12),
                            Text(l10n.actionShare),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // A plain scrolling Column, not a ListView — the Container (not
            // the Column) carries the background/padding so it paints the
            // same mood-tinted background the Scaffold itself does; a
            // ListView doesn't paint any background of its own. SafeArea
            // means the last photo can still scroll clear of the gesture
            // bar on a phone with a taller one.
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  color: screenBackground,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      Center(
                        child: InkWell(
                          // Only tappable in edit mode, same gating as the title,
                          // tags, photos, and voice note — it used to be tappable
                          // any time the entry wasn't deleted, with no visual cue
                          // either way, so it wasn't obvious whether tapping it
                          // would actually do anything.
                          onTap: _editingText
                              ? () => _pickMood(context, appState, entry)
                              : null,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: entry.mood.swatch,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MoodEmoji(mood: entry.mood, size: 26),
                                const SizedBox(width: 8),
                                // The mood's own label, not entry.title — title is
                                // now an independently editable headline (below)
                                // and may not have anything to do with the mood.
                                Text(
                                  l10n.entryFeelingMood(
                                    moodLabel(context, entry.mood),
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: entry.mood.onSwatch,
                                  ),
                                ),
                                // Same edit-affordance pattern as the title's own
                                // pencil — only shown in edit mode, so it's clear
                                // this is tappable right when it actually is.
                                if (_editingText) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: entry.mood.onSwatch,
                                  ),
                                ],
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
                            ? Text(
                                entryDisplayTitle(context, entry),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                              )
                            : _editingTitle
                            ? TapRegion(
                                // Tapping outside still auto-saves (same as
                                // the tag "+" field below), but there's also
                                // an explicit tick now — tap-outside alone
                                // isn't an obvious "save" action to everyone.
                                onTapOutside: (_) =>
                                    _saveTitle(appState, entry),
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
                                          maxLengthEnforcement:
                                              MaxLengthEnforcement.enforced,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: scheme.onSurface,
                                              ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            hintText: l10n.journalTitleHint,
                                            counterText: '',
                                          ),
                                          onSubmitted: (_) =>
                                              _saveTitle(appState, entry),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _saveTitle(appState, entry),
                                        customBorder: const CircleBorder(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 20,
                                            color: scheme.primary,
                                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          entryDisplayTitle(context, entry),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: scheme.onSurface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _relativeDate(entry.dateTime),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      if (_editingText) ...[
                        const SizedBox(height: 16),
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
                            for (final themeEntry in journalThemes.entries)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ThemeSwatch(
                                  color: resolveJournalThemeColor(
                                    themeEntry.key,
                                    scheme.brightness,
                                  ),
                                  selected: entry.themeName == themeEntry.key,
                                  onTap: () => appState.updateEntry(
                                    entry.id,
                                    themeName: themeEntry.key,
                                  ),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                              ),
                            ],
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
                                  onDelete: _editingText
                                      ? () => appState.removeVoiceNote(entry.id)
                                      : null,
                                  // Same white/grey swap as the tag chips and
                                  // text field right above it — otherwise this
                                  // stayed a fixed grey no matter which Writing
                                  // Theme was picked, a visible mismatch against
                                  // an actually-tinted card.
                                  backgroundColor: tagChipColor,
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
                                  onPressed: () => _recordVoiceNote(
                                    context,
                                    appState,
                                    entry,
                                  ),
                                  icon: const Icon(Icons.mic, size: 18),
                                  label: Text(l10n.entryAddVoiceNote),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                            ),
                          ],
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
                                    label: activityLabel(context, tag),
                                    onRemove: () =>
                                        appState.removeLabel(entry.id, tag),
                                    // Same edit-mode gating as the title, photos,
                                    // and voice note — _editingText can only be
                                    // true when canEdit already is, so this
                                    // covers the deleted-entry read-only case too.
                                    showRemove: _editingText,
                                    color: tagChipColor,
                                  ),
                                // Hidden once at the tag cap, rather than still
                                // inviting a tap that would just add past it.
                                if (_editingText &&
                                    entry.labels.length < _maxTags)
                                  _AddTagButton(
                                    key: _addTagKey,
                                    fillColor: tagChipColor,
                                    onAdd: (tag) {
                                      if (entry.labels.length >= _maxTags) {
                                        showAppSnackBar(
                                          context,
                                          l10n.entryTagCap(_maxTags),
                                        );
                                        return;
                                      }
                                      appState.addLabel(entry.id, tag);
                                    },
                                  ),
                              ],
                            ),
                            // Skipped when the tags Wrap above has nothing in it
                            // (no tags, and not in edit mode so no "+" button
                            // either) — otherwise this left a fixed gap of empty
                            // space above the content text for no reason, instead
                            // of the text just starting at the top of the card.
                            if (entry.labels.isNotEmpty || _editingText)
                              const SizedBox(height: 16),
                            _editingText
                                ? TextField(
                                    controller: _textController,
                                    autofocus: true,
                                    maxLines: null,
                                    minLines: 6,
                                    maxLength: _maxTextLength,
                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: scheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: l10n.journalWriteHint,
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
                                    entry.text.isEmpty
                                        ? l10n.entryNoReflectionYet
                                        : entry.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: entry.text.isEmpty
                                          ? scheme.onSurfaceVariant
                                          : scheme.onSurface,
                                      fontStyle: entry.text.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                    ),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                              ),
                            ],
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
                                    ? l10n.entryMomentsCaptured
                                    : l10n.entryMomentsCapturedCount(
                                        entry.photos.length,
                                        JournalEntry.maxPhotos,
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
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
                                      onRemove: () =>
                                          appState.removePhoto(entry.id, i),
                                      size: double.infinity,
                                      // Hidden until the entry is put into edit
                                      // mode — a plain view of an entry shouldn't
                                      // be cluttered with delete affordances.
                                      showDeleteButton: _editingText,
                                    ),
                                  if (_editingText &&
                                      entry.photos.length <
                                          JournalEntry.maxPhotos)
                                    AddPhotoTile(
                                      label: entry.photos.isEmpty
                                          ? l10n.journalAddPhoto
                                          : l10n.journalAddMorePhoto,
                                      onTap: () =>
                                          _addPhoto(context, appState, entry),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () =>
                                    _restore(context, appState, entry),
                                icon: const Icon(Icons.restore, size: 18),
                                label: Text(l10n.deletedEntriesRestore),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.error,
                                  side: BorderSide(
                                    color: scheme.errorContainer,
                                  ),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () => _confirmDeleteForever(
                                  context,
                                  appState,
                                  entry,
                                ),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 18,
                                ),
                                label: Text(l10n.deletedEntriesDeleteForever),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
                        tooltip: l10n.actionCancel,
                        onPressed: () => _cancelEditingText(appState, entry),
                        child: const Icon(Icons.close),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'entry-save-${entry.id}',
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        tooltip: l10n.actionSave,
                        onPressed: () => _saveText(context, appState, entry),
                        child: const Icon(Icons.save),
                      ),
                    ],
                  )
                : FloatingActionButton(
                    heroTag: 'entry-edit-${entry.id}',
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    tooltip: l10n.entryEditTooltip,
                    onPressed: () => _startEditingText(entry),
                    child: const Icon(Icons.edit),
                  ),
          );
        },
      ),
    );
  }
}

/// A tag chip with an always-visible ✕ to remove it — no long-press or
/// confirm dialog needed since the ✕ is already an explicit, deliberate
/// tap target (unlike e.g. swipe-to-delete on a whole entry, which is
/// riskier to trigger by accident and still gets a confirm dialog).
class _RemovableTagChip extends StatelessWidget {
  const _RemovableTagChip({
    required this.label,
    required this.onRemove,
    this.showRemove = true,
    this.color,
  });
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
      padding: EdgeInsets.only(
        left: 14,
        right: showRemove ? 6 : 14,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (showRemove)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
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
  const _AddTagButton({
    super.key,
    required this.onAdd,
    required this.fillColor,
  });
  final ValueChanged<String> onAdd;

  /// Same Writing-Theme-aware background as the tag chips and content
  /// editor around it (see EntryDetailScreen's own tagChipColor, and
  /// _RemovableTagChip's matching fallback) — this used to fall back to
  /// the app-wide input fill (a plain white/near-white), which blended
  /// straight into the white card behind it instead of reading as its own
  /// distinct field the way the grey tag chips did. Null (dark mode, or
  /// no Writing Theme set) falls back to the same plain neutral color the
  /// tag chips themselves fall back to.
  final Color? fillColor;

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

  /// Called by EntryDetailScreen's own PopScope handler, via a GlobalKey,
  /// right before it saves and finishes a back-press mid-edit — flushes
  /// whatever's still typed in this field the same way tapping its own
  /// checkmark would, so a tag typed but never explicitly confirmed isn't
  /// silently dropped by a misclick back the same way the body text used
  /// to be. A no-op if this field isn't even open, or has nothing typed
  /// in it (_confirm/addLabel already handle blank input as a no-op).
  void confirmPendingTag() {
    if (_adding) _confirm();
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
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary),
          ),
          child: Icon(Icons.add, size: 16, color: scheme.primary),
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
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: AppLocalizations.of(context)!.entryNewTagHint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor:
                      widget.fillColor ??
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
                onSubmitted: (_) => _confirm(),
              ),
            ),
            InkWell(
              onTap: _confirm,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
