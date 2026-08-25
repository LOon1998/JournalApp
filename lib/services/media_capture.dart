import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_lock_service.dart';

/// Shows a small "Take Photo / Choose from Gallery" sheet and returns the
/// picked source, or null if the user backed out without choosing.
Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.settingsTakePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.settingsChooseFromGallery),
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
  // Launching the camera (or even the gallery, on some devices/OS
  // versions) backgrounds this app exactly the same way switching away
  // to another app does — see ExternalActivityGuard's own doc for why
  // this is what stops that from being mistaken for someone actually
  // leaving and re-locking the app the moment it returns. begin()/end()
  // bracket the *whole* pick, not just its launch — some camera apps
  // (Samsung's own included) cycle through more than one pause/resume
  // while still mid-pick, and only bracketing the launch would leave
  // later transitions in that same pick looking like a genuine
  // backgrounding again.
  ExternalActivityGuard.begin();
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } finally {
    ExternalActivityGuard.end();
  }
}

/// Same idea as [pickPhotoAsBase64], sized down further (a profile photo
/// only ever renders as a small circle, and — unlike entry photos — this
/// one rides along in *every* AppState sync, cloud and local, so it's
/// worth keeping noticeably smaller).
Future<String?> pickAvatarAsBase64(ImageSource source) async {
  // See pickPhotoAsBase64's own comment on ExternalActivityGuard.begin().
  ExternalActivityGuard.begin();
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } finally {
    ExternalActivityGuard.end();
  }
}
