import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/floating_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(
        // No back arrow and no "Lumina" branding here — this screen
        // already has its own "Settings" heading right below, and the
        // close button below is the one way to dismiss.
        automaticallyImplyLeading: false,
        // AppBar's own `actions` has its own built-in end padding, which
        // doesn't line up with where the settings gear icon actually
        // sits on LuminaTopBar. Rebuilding the same
        // Padding(horizontal: 24) + Row wrapper LuminaTopBar itself uses
        // puts this X in that exact same spot instead.
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: scheme.primary),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Column(
            children: [
              Text('Settings',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Customize your digital hug.', style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 24),
          FloatingCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.self_improvement, size: 36, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.userName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(appState.userEmail, style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _showComingSoon(context, 'Edit Profile'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
                        child: const Text('Edit Profile', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.palette, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              icon: Icons.light_mode,
                              label: 'Light',
                              selected: appState.themeMode == ThemeMode.light,
                              onTap: () => appState.setThemeMode(ThemeMode.light),
                            ),
                          ),
                          Expanded(
                            child: _ModeButton(
                              icon: Icons.dark_mode,
                              label: 'Dark',
                              selected: appState.themeMode == ThemeMode.dark,
                              onTap: () => appState.setThemeMode(ThemeMode.dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.smart_toy, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('AI Companion', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: appState.auraEnabled,
                  onChanged: appState.setAuraEnabled,
                  title: const Text('Enable Aura'),
                  subtitle: const Text('Let the floating Aura chatbot accompany you.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(children: [
                    Icon(Icons.settings, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('General', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
                SwitchListTile(
                  value: appState.notificationsEnabled,
                  onChanged: appState.setNotificationsEnabled,
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context, 'Privacy & Security'),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context, 'Help & Support'),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About Lumina'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context, 'About Lumina'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            color: scheme.tertiaryContainer.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.bug_report_outlined, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Text('Testing Tools',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(
                  "Not a real feature — just here to make QA-ing today's UI states easier.",
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmClearToday(context, appState),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text("Clear Today's Entries"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _confirmLogOut(context),
                  child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showAppSnackBar(context, '$feature — coming soon');
  }

  void _confirmClearToday(BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear today's entries?"),
        content: const Text(
            "Soft-deletes every entry logged today (they're recoverable from History, same as swipe-delete) — lets you re-test things like the Insights check-in card that only show when today has nothing logged yet."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      appState.clearTodayEntriesForTesting();
      showAppSnackBar(context, "Today's entries cleared");
    }
  }

  void _confirmLogOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign back in to see your journal."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: selected ? scheme.primary : scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
