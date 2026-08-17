import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// The "N entries | History" row shown above an entry list — entry count
/// on the left, a thin vertical divider, then a tap target opening that
/// day's Deleted Entries history. Shared by the Journal timeline (today's
/// entries) and the Calendar day view (the selected day's entries) so
/// both look identical.
class EntriesHistoryRow extends StatelessWidget {
  const EntriesHistoryRow({super.key, required this.entryCount, required this.onHistoryTap});

  final int entryCount;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.entriesHistoryCount(entryCount),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(width: 1, height: 12, color: scheme.outlineVariant),
        const SizedBox(width: 8),
        InkWell(
          onTap: onHistoryTap,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 14, color: scheme.primary),
              const SizedBox(width: 2),
              Text(l10n.journalHistory, style: TextStyle(color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
