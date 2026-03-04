import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/background_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _pollOptions = [
    (label: '15 seconds', duration: Duration(seconds: 15)),
    (label: '30 seconds', duration: Duration(seconds: 30)),
    (label: '1 minute', duration: Duration(minutes: 1)),
    (label: '5 minutes', duration: Duration(minutes: 5)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Poll Interval
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Poll Interval',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ..._pollOptions.map((option) {
            final selected = settings.pollInterval == option.duration;
            return ListTile(
              title: Text(option.label),
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .setPollInterval(option.duration),
            );
          }),

          const Divider(),

          // Notifications
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle:
                const Text('Get notified when runs finish or crash'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(value);
            },
          ),

          const Divider(),

          // Clear Cache
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Cache'),
            subtitle: const Text('Invalidate all cached data'),
            onTap: () {
              ref.invalidate(authenticatedClientProvider);
              ref.invalidate(apiKeyProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.error),
            title: Text('Logout',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const Divider(),

          // App info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('W&B Viewer',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await BackgroundService.cancelAll();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
