import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_tile.dart';
import 'entry_detail_screen.dart';

/// "Deleted Entries" history for a single day — lets you restore an entry
/// you swiped away by mistake, or permanently delete it (individually or
/// all at once). Scoped to [day] (rather than showing everything ever
/// deleted across all time) so it matches whichever day you were looking
/// at when you opened it.
class DeletedEntriesScreen extends StatefulWidget {
  const DeletedEntriesScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<DeletedEntriesScreen> createState() => _DeletedEntriesScreenState();
}

class _DeletedEntriesScreenState extends State<DeletedEntriesScreen> {
  // Same page size as Journal's own entries carousel, for consistency —
  // with the 20/day deleted cap that's up to 4 pages.
  static const _entriesPerPage = 5;

  // null means "not navigated yet" — resolves to page 0, since
  // deletedEntriesOn is already sorted most-recently-deleted first.
  int? _currentPageIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final deleted = appState.deletedEntriesOn(widget.day);
    final pageCount = deleted.isEmpty
        ? 0
        : (deleted.length / _entriesPerPage).ceil();
    final page = pageCount == 0
        ? 0
        : (_currentPageIndex ?? 0).clamp(0, pageCount - 1);
    final pageStart = page * _entriesPerPage;
    final pageEnd = (pageStart + _entriesPerPage).clamp(0, deleted.length);
    final pageEntries = deleted.sublist(pageStart, pageEnd);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: scheme.onSurfaceVariant),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.deletedEntriesTitle,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              DateFormat.yMMMMd(
                Localizations.localeOf(context).toString(),
              ).format(widget.day),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: deleted.isEmpty
                ? null
                : () => _confirmClearAll(context, appState, deleted.length),
            icon: Icon(
              Icons.delete_sweep,
              size: 18,
              color: deleted.isEmpty ? scheme.outlineVariant : scheme.error,
            ),
            label: Text(
              l10n.deletedEntriesClearAll,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: deleted.isEmpty ? scheme.outlineVariant : scheme.error,
              ),
            ),
          ),
        ],
      ),
      // SafeArea — a pushed screen with no bottom nav bar of its own, same
      // reasoning as Settings/Weekly Detail/Entry Detail's own fix for
      // the same gesture-bar clipping.
      body: SafeArea(
        child: deleted.isEmpty
            ? _EmptyState(scheme: scheme, day: widget.day)
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  Text(
                    l10n.deletedEntriesSlotsUsed(
                      deleted.length,
                      AppState.maxDeletedEntriesPerDay,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.deletedEntriesExpiryNote(
                      AppState.deletedEntryExpiry.inDays,
                    ),
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in pageEntries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DeletedEntryCard(entry: entry),
                    ),
                  if (pageCount > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: page > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: IconButton(
                            onPressed: page > 0
                                ? () => setState(
                                    () => _currentPageIndex = page - 1,
                                  )
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.deletedEntriesPrevPage,
                          ),
                        ),
                        for (var i = 0; i < pageCount; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
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
                                ? () => setState(
                                    () => _currentPageIndex = page + 1,
                                  )
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.deletedEntriesNextPage,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  void _confirmClearAll(
    BuildContext context,
    AppState appState,
    int count,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletedEntriesConfirmClearAllTitle),
        content: Text(
          l10n.deletedEntriesConfirmClearAllBody(
            count,
            DateFormat.yMMMMd(
              Localizations.localeOf(context).toString(),
            ).format(widget.day),
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
              l10n.deletedEntriesDeleteAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      appState.clearDeletedEntriesOn(widget.day);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme, required this.day});
  final ColorScheme scheme;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.delete_sweep,
                size: 48,
                color: scheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deletedEntriesEmptyTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deletedEntriesEmptyBody(
                DateFormat.yMMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(day),
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedEntryCard extends StatelessWidget {
  const _DeletedEntryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: scheme.surfaceContainerLowest,
        // Read-only view — EntryDetailScreen hides every editing
        // affordance (including its own edit FAB) for a deleted entry,
        // since it hasn't been restored yet. The Restore/Delete Forever
        // buttons below sit inside this same tap target but are their
        // own Material buttons, so tapping them doesn't trigger this
        // outer navigation.
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EntryDetailScreen(entryId: entry.id),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: scheme.errorContainer),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                entry.mood.icon,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(entry.dateTime)} · ${DateFormat('h:mm a', Localizations.localeOf(context).toString()).format(entry.dateTime)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.deletedEntriesBadge,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          entryDisplayTitle(context, entry),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (entry.photos.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 15,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ],
                                      if (entry.voiceNote != null) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.mic,
                                          size: 15,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (entry.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            entry.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (entry.photos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          PhotoStrip(photos: entry.photos),
                        ],
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: scheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.primaryContainer,
                                  foregroundColor: scheme.onPrimaryContainer,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () => _restore(context),
                                icon: const Icon(Icons.restore, size: 18),
                                label: Text(
                                  l10n.deletedEntriesRestore,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () => _confirmDeleteForever(context),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 18,
                                ),
                                label: Text(
                                  l10n.deletedEntriesDeleteForever,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restore(BuildContext context) {
    final appState = AppStateScope.of(context);
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
  }

  void _confirmDeleteForever(BuildContext context) async {
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
      AppStateScope.of(context).permanentlyDeleteEntry(entry.id);
    }
  }
}
