import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

void _openPhoto(BuildContext context, Uint8List bytes) => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );

/// A saved photo shown as a rounded-square tile with an always-visible ✕
/// overlay to remove it, and tap-to-view full-screen. Shared by the
/// Journal composer's in-progress photo row and the entry detail screen's
/// "Moments Captured" grid so both look identical.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.base64Photo,
    required this.onRemove,
    this.size = 96,
    this.showDeleteButton = true,
  });

  final String base64Photo;
  final VoidCallback onRemove;
  final double size;

  /// Whether the ✕ overlay is shown at all. The Journal composer is
  /// always "editing" by nature, so it stays on there — but the entry
  /// detail screen's read view uses this to hide it until the entry is
  /// actually put into edit mode, so a plain view of an entry isn't
  /// cluttered with delete affordances.
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64Photo);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPhoto(context, bytes),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
          ),
        ),
        if (showDeleteButton)
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// The "Add Photo"/"Add More" tile that sits alongside [PhotoTile]s. Flutter
/// has no built-in dashed border, and pulling in a package for one felt
/// like overkill for a single tile (the same call made for the tag "+"
/// button elsewhere in this app) — a plain solid outline stands in for one.
class AddPhotoTile extends StatelessWidget {
  const AddPhotoTile({super.key, required this.label, required this.onTap, this.size = 96});

  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 20, color: scheme.primary),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// A compact read-only row of small photo thumbnails (tap one to view it
/// full-screen) — used on entry list rows (Journal timeline, Calendar day
/// detail) so it's visible at a glance that an entry has photos attached,
/// without needing to open it.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, this.size = 48});

  final List<String> photos;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final bytes = base64Decode(photos[index]);
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openPhoto(context, bytes),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
