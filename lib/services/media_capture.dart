import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a small "Take Photo / Choose from Gallery" sheet and returns the
/// picked source, or null if the user backed out without choosing.
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

/// Picks a photo from [source] and returns it base64-encoded, ready to
/// embed directly in an entry's `photos` list. The `imageQuality`/
/// `maxWidth`/`maxHeight` below are image_picker's own built-in
/// compression — done before the bytes ever reach us, so no separate
/// image-processing package is needed.
///
/// Returns null if the user cancelled the picker.
Future<String?> pickPhotoAsBase64(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 70,
    maxWidth: 1024,
    maxHeight: 1024,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}
