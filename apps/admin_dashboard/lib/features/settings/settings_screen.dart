import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:auth/auth.dart';
import 'theme_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthState>().user;

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: GLSpacing.lg),
          Expanded(
            child: ListView(
              children: [
                _buildSettingsSection(
                  context,
                  'Account Profile',
                  [
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? 'Not available'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Role'),
                      subtitle: Text(user?.role ?? 'Administrator'),
                    ),
                  ],
                ),
                _buildSettingsSection(
                  context,
                  'System Configuration',
                  [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Enable/Disable global alerts'),
                      value: true,
                      onChanged: (val) {},
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Toggle system theme'),
                      value: context.watch<ThemeState>().themeMode == ThemeMode.dark,
                      onChanged: (val) => context.read<ThemeState>().toggleTheme(val),
                    ),
                  ],
                ),
                _buildSettingsSection(
                  context,
                  'Security',
                  [
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () => context.read<AuthState>().logout(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GLSpacing.md),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(GLRadius.lg),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: GLSpacing.md),
      ],
    );
  }
}
