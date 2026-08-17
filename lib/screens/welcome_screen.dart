import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';

/// Shown once, right after a brand-new account finishes signing up (see
/// AuthService.consumeJustSignedUp) — never on a returning sign-in. Matches
/// the Lumina web mockups' welcome screen, with the illustration swapped
/// for a plain icon badge (no bundled artwork asset) — same "digital hug"
/// framing Settings already uses. Shows the photo picked on the sign-up
/// screen in that badge when there is one, since by this point AppState
/// already exists and has it (see main.dart) — falls back to the same
/// icon badge otherwise.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final photoBase64 = AppStateScope.of(context).profilePhotoBase64;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primaryContainer,
                      image: photoBase64 != null
                          ? DecorationImage(image: MemoryImage(base64Decode(photoBase64)), fit: BoxFit.cover)
                          : null,
                      boxShadow: [
                        BoxShadow(color: scheme.primary.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 4),
                      ],
                    ),
                    child: photoBase64 == null ? Icon(Icons.self_improvement, size: 88, color: scheme.onPrimaryContainer) : null,
                  ),
                  const SizedBox(height: 32),
                  Text(l10n.welcomeTitle,
                      textAlign: TextAlign.center,
                      style:
                          textTheme.headlineMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.self_improvement, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.welcomeStartButton,
                              style: textTheme.titleMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
