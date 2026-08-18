import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(selection.first),
          ),
          const SizedBox(height: 28),
          Text('Notifications', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Enable reminders'),
              subtitle: const Text('Get notified when a task is due'),
              onTap: () async {
                final granted = await NotificationService.instance
                    .requestPermissions();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      granted
                          ? 'Notifications enabled'
                          : 'Notifications permission was not granted',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          Text('About', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Daily'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }
}
