import 'package:flutter/material.dart';

/// Shows a snackbar with the app's standard, short-lived duration.
///
/// Flutter's [SnackBar] defaults to a 4-second [SnackBar.duration], which
/// reads as sluggish for the quick confirmations this app shows ("Entry
/// saved", "Pick a mood first", etc.) — most apps dismiss these closer to
/// 2 seconds. [SnackBarThemeData] has no `duration` field to set this once
/// app-wide, so this helper is the single place it's configured instead of
/// repeating a magic duration at every call site.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  // Overridable for the rare longer message (e.g. the "check your spam
  // folder" reminder after requesting a password reset) that genuinely
  // needs more than 2 seconds to actually read — the short default stays
  // as the norm for everything else.
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
}
