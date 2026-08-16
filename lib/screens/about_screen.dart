import 'package:flutter/material.dart';
import '../widgets/floating_card.dart';
import 'privacy_policy_screen.dart';

/// Version shown at the bottom of this screen — kept in sync with
/// pubspec.yaml's own `version:` field by hand (this project doesn't pull
/// in package_info_plus just to read that value back at runtime).
const _appVersion = '1.0.0';

/// Reached from Settings' "About Moodlet" row — brand story, core values,
/// and version/legal info. Matches the provided web mockup's layout and
/// copy, restyled with this app's own FloatingCard/theme conventions
/// instead of the mockup's literal Tailwind colors, and using the real
/// Moodlet logo mark (assets/branding/logoIcon.png).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About Moodlet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  // logo.png (icon + "Moodlet" + subtitle baked into one
                  // image) — not the boxed square logoIcon.png treatment
                  // this used to have; that square container was sized
                  // for a compact icon-only mark, not this wider
                  // icon+wordmark image.
                  Image.asset('assets/branding/logo.png', height: 72),
                  const SizedBox(height: 20),
                  Text('Your Digital Sanctuary',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    "Moodlet was created as a safe, non-judgmental space for emotional reflection. We believe "
                    "taking a moment for yourself shouldn't feel like a chore, but a gentle habit of self-care. "
                    "Here, you can pause, breathe, and untangle your thoughts in a calm space designed for "
                    "mindful growth.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Our Core Values',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _ValueCard(
              icon: Icons.lock_person_outlined,
              color: scheme.secondaryContainer,
              onColor: scheme.secondary,
              title: 'Privacy First',
              body: 'Your reflections belong solely to you. Your journal is stored in your own private account, '
                  "never shared or sold, and yours to delete completely whenever you'd like.",
            ),
            const SizedBox(height: 12),
            _ValueCard(
              icon: Icons.eco_outlined,
              color: scheme.tertiaryContainer,
              onColor: scheme.tertiary,
              title: 'Mindful Growth',
              body: 'We design interactions to foster gentle self-awareness, avoiding addictive loops in favor '
                  'of intentional, meaningful check-ins.',
            ),
            const SizedBox(height: 12),
            _ValueCard(
              icon: Icons.palette_outlined,
              color: scheme.primaryContainer,
              onColor: scheme.primary,
              title: 'Creative Expression',
              body: 'An open canvas for your emotions — words, mood colors, photos, voice notes, and tags — so '
                  'your feelings can take whatever shape suits them.',
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
                child: const Text('Privacy Policy'),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Version $_appVersion', style: TextStyle(fontSize: 12, color: scheme.outline)),
            ),
            Center(
              child: Text('© ${DateTime.now().year} Moodlet Journal. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.color,
    required this.onColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final Color onColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(icon, color: onColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
