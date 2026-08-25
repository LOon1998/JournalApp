import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// Reached from Settings' "Help & Support" row. Deliberately a small
/// fraction of the original mockup: this app is maintained by one person,
/// not a support team, so a search bar, help-article categories, and a
/// live chat widget would all be promising something that isn't actually
/// there. What's real and worth keeping: a couple of accurate FAQ
/// answers (plain static text, no backend needed). No in-app "email us"
/// link — there's no real support inbox behind one, and Play Store only
/// requires a support contact in the Play Console listing itself, not
/// inside the app's own UI.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsHelpSupport)),
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
                  Text(l10n.helpSupportHeroTitle,
                      style: textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.helpSupportHeroSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l10n.helpSupportFaqTitle,
                style: textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _FaqTile(question: l10n.helpSupportFaq1Q, answer: l10n.helpSupportFaq1A),
            _FaqTile(question: l10n.helpSupportFaq2Q, answer: l10n.helpSupportFaq2A),
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
      // The background lives on this Material (not a plain
      // Container/DecoratedBox) — ExpansionTile's header is a ListTile
      // under the hood, and ListTile paints its own background/ink
      // splashes on the *nearest* Material ancestor. A colored
      // DecoratedBox with no Material of its own in between just hides
      // both, which is what a Container's own decoration would do here.
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
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
      ),
    );
  }
}
