import 'package:flutter/material.dart';
import '../app_info.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Last updated: $_lastUpdated', style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 16),
            const _Section(
              title: 'Overview',
              body: 'Moodlet ("we", "our", "the app") is a personal journaling app. This policy explains what '
                  'information the app collects, how it is used, and the choices you have. Using Moodlet means '
                  'you agree to the practices described here.',
            ),
            // Matches auth_service.dart (email/password sign-up) and
            // settings_screen.dart's editable display name/profile photo.
            const _Section(
              title: 'Information We Collect',
              body: '• Account information: the email address and password you sign up with (your password is '
                  'never visible to us — Firebase Authentication handles it directly).\n'
                  '• Profile info you choose to add: a display name and/or profile photo.\n'
                  '• Journal content: anything you write, the mood and tags/activities you record, and any '
                  'photos or voice notes you attach to an entry.\n'
                  '• Optional AI key: if you choose to connect a Google Gemini API key in Settings for AI-powered '
                  'features, that key is stored so the app can use it — see "Optional AI Features" below.\n\n'
                  'We do not collect analytics, advertising identifiers, or location data, and Moodlet contains '
                  'no ads or third-party trackers.',
            ),
            // Matches cloud_sync_service.dart / app_state.dart — one
            // Firestore document per account, gated by firestore.rules to
            // only that account's own signed-in user.
            const _Section(
              title: 'How We Store Your Information',
              body: 'Your account and journal data are stored using Firebase Authentication and Cloud Firestore '
                  '(Google Cloud infrastructure), encrypted in transit. Access rules restrict your data to your '
                  "own signed-in account — no other user can read or write it. A copy is also cached on your "
                  "device so the app works offline; that local copy is cleared when you delete your account.",
            ),
            const _Section(
              title: 'How We Use Your Information',
              body: '• To create and secure your account, and let you sign back in on any device.\n'
                  "• To store and sync your journal entries so they're available whenever you open the app.\n"
                  '• To show you your own mood trends and patterns within the app (Insights).\n'
                  '• To send an optional local daily reminder notification, if you turn that on — this is '
                  'scheduled entirely on your device and involves no data being sent anywhere.\n\n'
                  'We do not use your journal content for advertising, and we do not sell your information to '
                  'anyone.',
            ),
            // Matches gemini_service.dart — only ever called if the user
            // has entered their own key in Settings; resolveGeminiApiKey
            // returns null (and every AI code path is skipped) otherwise.
            const _Section(
              title: 'Optional AI Features',
              body: 'Moodlet can use the Google Gemini API to suggest reflection prompts, refine your weekly mood '
                  "trend, or generate a title from an entry — but only if you provide your own Gemini API key in "
                  'Settings. If you do, the relevant entry text is sent directly to Google\'s Gemini API to '
                  'generate that response, subject to Google\'s own privacy terms. If no key is set, none of '
                  'this happens and no journal content ever leaves your device for this purpose.',
            ),
            // Matches app_lock_service.dart — SharedPreferences only,
            // deliberately never part of the Firestore-synced AppState.
            const _Section(
              title: 'On-Device Security Features',
              body: 'Pattern Lock (Settings → Privacy & Security) is stored only on your '
                  "device and is never synced to our servers or visible to us — a drawn pattern is stored only "
                  'as an irreversible hash, never in a form that could be read back.',
            ),
            // Matches auth_service.dart's deleteAccount — deletes the
            // Firestore doc, the local cache, and the Auth account itself.
            const _Section(
              title: 'Data Retention & Deletion',
              body: 'Your data is kept for as long as your account exists. Deleting an entry from your timeline '
                  'moves it to History for a limited time before it\'s permanently removed, so you can restore '
                  'it if that was a mistake. You can permanently delete your entire account and all associated '
                  'data at any time from Settings → Delete Account — this immediately and permanently removes '
                  'your journal data, your local device cache, and your account itself.',
            ),
            const _Section(
              title: "Children's Privacy",
              body: 'Moodlet is not directed at children under 13, and we do not knowingly collect information '
                  'from anyone under that age. If you believe a child has provided us with personal information, '
                  'please contact us using the details below and we will delete it.',
            ),
            const _Section(
              title: 'Changes to This Policy',
              body: 'If this policy changes, the "Last updated" date at the top of this page will change too. '
                  'Continuing to use Moodlet after an update means you accept the revised policy.',
            ),
            _Section(
              title: 'Contact Us',
              body: 'Questions about this policy or your data? Reach us at $supportEmail.',
            ),
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
