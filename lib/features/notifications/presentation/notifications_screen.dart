import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Enable Daily Reminders'),
                subtitle: const Text('Fajr, Dhuhr, Asr, Maghrib, Isha reminders'),
                value: settings.notificationsEnabled,
                onChanged: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setNotifications(value),
              ),
              const SizedBox(height: 8),
              const Card(
                child: ListTile(
                  title: Text('Notification permissions'),
                  subtitle: Text(
                    'Configured and ready for platform channel integration.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
