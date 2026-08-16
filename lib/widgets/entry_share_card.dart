import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import 'mini_chip.dart';

/// A compact, self-contained "share card" rendering of a [JournalEntry] —
/// built specifically to be captured as a PNG (see
/// EntryDetailScreen._shareEntry) rather than shown on screen itself.
/// Deliberately a *summary*, not the full entry: a card showing an
/// unbounded wall of text wouldn't work as a fixed-size shareable image,
/// so the body text is truncated and this focuses on what actually reads
/// well shared into a chat — mood, title, a short excerpt, photos, tags.
///
/// Voice notes can't go *inside* a static image at all — see the
/// "🎤 Voice note" badge below, which just signals one exists; the actual
/// audio is attached as a separate file alongside this image (see
/// EntryDetailScreen._shareEntry).
class EntryShareCard extends StatelessWidget {
  const EntryShareCard({super.key, required this.entry});

  final JournalEntry entry;

  static const _width = 360.0;
  static const _maxExcerptChars = 220;

  @override
  Widget build(BuildContext context) {
    final mood = entry.mood;
    final excerpt = entry.text.length > _maxExcerptChars
        ? '${entry.text.substring(0, _maxExcerptChars).trimRight()}…'
        : entry.text;

    return Material(
      // Always light-themed regardless of the app's own current
      // theme mode — a shared image should look the same no matter who
      // views it or what device/theme they're on, not silently come out
      // dark-on-dark if the sender happened to have dark mode on.
      color: Colors.white,
      child: Container(
        width: _width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: mood.swatch, child: Text(mood.emoji, style: const TextStyle(fontSize: 20))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black87)),
                      Text(_formatDate(entry.dateTime), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            if (excerpt.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(excerpt, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
            ],
            if (entry.photos.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final photo in entry.photos.take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(base64Decode(photo), width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ],
            if (entry.voiceNote != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🎤', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text('Voice note attached',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ],
              ),
            ],
            if (entry.labels.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final label in entry.labels) MiniChip(label: label)]),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.self_improvement, size: 16, color: mood.onSwatch),
                const SizedBox(width: 6),
                const Text('Lumina', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
