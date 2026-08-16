import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_info.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';

/// Reached from Settings' "Help & Support" row. Deliberately a small
/// fraction of the original mockup: this app is maintained by one person,
/// not a support team, so a search bar, help-article categories, and a
/// live chat widget would all be promising something that isn't actually
/// there. What's real and worth keeping: a couple of accurate FAQ
/// answers (plain static text, no backend needed) and a direct way to
/// email for anything else.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: supportEmail, queryParameters: {'subject': 'Lumina Support'});
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      showAppSnackBar(context, "Couldn't open your email app — you can reach us at $supportEmail");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.waving_hand_outlined, size: 32, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text("We're here to help",
                      style: textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'A couple of quick answers below — or reach out directly and we\'ll get back to you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Frequently Asked Questions',
                style: textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const _FaqTile(
              question: 'Is my data secured?',
              answer: 'Yes — your account and journal are protected by Firebase Authentication and Cloud '
                  'Firestore, with access rules that restrict your data to your own signed-in account only. '
                  'See the Privacy Policy (About Lumina) for the full details.',
            ),
            const _FaqTile(
              question: 'Can I use Lumina on multiple devices?',
              answer: 'Yes — sign in with the same account on any device and your journal, mood history, and '
                  "settings will all be right there. Fingerprint Unlock and Pattern Lock are the only "
                  "exceptions — those are set per-device, so you'll set them up again on a new one.",
            ),
            const SizedBox(height: 28),
            FloatingCard(
              onTap: () => _emailSupport(context),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: scheme.tertiaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.email_outlined, color: scheme.tertiary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Still need a hand?', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Email us — $supportEmail',
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        // Removes the default divider ExpansionTile draws above/below
        // itself when open — one clean rounded card, not a card with a
        // stray line cutting through it.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(answer, style: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
