import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../models/journal_entry.dart';
import '../theme/app_theme.dart';

/// "Deleted Entries" history — lets you restore an entry you swiped away
/// by mistake, or permanently delete it (individually or all at once).
class DeletedEntriesScreen extends StatelessWidget {
  const DeletedEntriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final deleted = appState.deletedEntries;
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(color: scheme.onSurfaceVariant),
            title: Text('Deleted Entries',
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 20)),
            centerTitle: true,
            actions: [
              TextButton.icon(
                onPressed: deleted.isEmpty ? null : () => _confirmClearAll(context, appState, deleted.length),
                icon: Icon(Icons.delete_sweep, size: 18, color: deleted.isEmpty ? scheme.outlineVariant : scheme.error),
                label: Text('Clear All',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: deleted.isEmpty ? scheme.outlineVariant : scheme.error)),
              ),
            ],
          ),
          body: deleted.isEmpty
              ? _EmptyState(scheme: scheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  itemCount: deleted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _DeletedEntryCard(entry: deleted[index]),
                ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, AppState appState, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete all?'),
        content: Text(
            'This will permanently delete all $count deleted ${count == 1 ? 'entry' : 'entries'}. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete All', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      appState.clearDeletedEntries();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.surfaceContainer, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.delete_sweep, size: 48, color: scheme.outlineVariant),
            ),
            const SizedBox(height: 16),
            Text('No Deleted Entries',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Entries you delete from your timeline show up here so you can restore them or remove them for good.',
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: scheme.surfaceContainerLowest,
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
                            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Icon(entry.mood.icon, size: 20, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(DateFormat.yMMMMd().format(entry.dateTime),
                                          style: TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: scheme.errorContainer, borderRadius: BorderRadius.circular(999)),
                                      child: Text('Deleted',
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600, color: scheme.error)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(entry.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
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
                          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Divider(height: 1, color: scheme.surfaceContainerHighest),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => AppStateScope.of(context).restoreEntry(entry.id),
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('Restore', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.error,
                                side: BorderSide(color: scheme.errorContainer),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _confirmDeleteForever(context),
                              icon: const Icon(Icons.delete_forever, size: 18),
                              label: const Text('Delete Forever', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
    );
  }

  void _confirmDeleteForever(BuildContext context) async {
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
      AppStateScope.of(context).permanentlyDeleteEntry(entry.id);
    }
  }
}
