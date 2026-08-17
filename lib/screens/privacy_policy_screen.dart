import 'package:flutter/material.dart';
import '../app_info.dart';
import '../l10n/generated/app_localizations.dart';

/// Kept as a plain constant (not derived from anything live) so it's
/// obvious this needs a manual bump whenever the policy text below
/// actually changes — same reasoning as About's _appVersion.
const _lastUpdated = 'August 16, 2026';

/// Reached from About Moodlet's "Privacy Policy" link. Plain, readable
/// legal-document styling (headings + paragraphs) rather than the
/// FloatingCard treatment used elsewhere — this is the one screen in the
/// app where a dense wall of standard legal text is actually the right
/// call, not a design gap.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(l10n.privacyPolicyLastUpdated(_lastUpdated), style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 16),
            _Section(title: l10n.privacyPolicyOverviewTitle, body: l10n.privacyPolicyOverviewBody),
            // Matches auth_service.dart (email/password sign-up) and
            // settings_screen.dart's editable display name/profile photo.
            _Section(title: l10n.privacyPolicyInfoCollectTitle, body: l10n.privacyPolicyInfoCollectBody),
            // Matches cloud_sync_service.dart / app_state.dart — one
            // Firestore document per account, gated by firestore.rules to
            // only that account's own signed-in user.
            _Section(title: l10n.privacyPolicyStorageTitle, body: l10n.privacyPolicyStorageBody),
            _Section(title: l10n.privacyPolicyUseTitle, body: l10n.privacyPolicyUseBody),
            // Matches gemini_service.dart — only ever called if the user
            // has entered their own key in Settings; resolveGeminiApiKey
            // returns null (and every AI code path is skipped) otherwise.
            _Section(title: l10n.privacyPolicyAiTitle, body: l10n.privacyPolicyAiBody),
            // Matches app_lock_service.dart — SharedPreferences only,
            // deliberately never part of the Firestore-synced AppState.
            _Section(title: l10n.privacyPolicySecurityTitle, body: l10n.privacyPolicySecurityBody),
            // Matches auth_service.dart's deleteAccount — deletes the
            // Firestore doc, the local cache, and the Auth account itself.
            _Section(title: l10n.privacyPolicyRetentionTitle, body: l10n.privacyPolicyRetentionBody),
            _Section(title: l10n.privacyPolicyChildrenTitle, body: l10n.privacyPolicyChildrenBody),
            _Section(title: l10n.privacyPolicyChangesTitle, body: l10n.privacyPolicyChangesBody),
            _Section(title: l10n.privacyPolicyContactTitle, body: l10n.privacyPolicyContactBody(supportEmail)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: scheme.primary)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 13.5, height: 1.55, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
