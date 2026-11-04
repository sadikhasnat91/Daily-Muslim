import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.name),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(value);
              },
              items: ThemeMode.values
                  .map(
                    (mode) => DropdownMenuItem<ThemeMode>(
                      value: mode,
                      child: Text(mode.name),
                    ),
                  )
                  .toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .setNotifications(value);
            },
          ),
          ListTile(
            title: const Text('Prayer City'),
            subtitle: Text(settings.city),
            onTap: () => _prompt(
              context,
              title: 'Update City',
              initialValue: settings.city,
              onSubmit: (value) =>
                  ref.read(settingsControllerProvider.notifier).setCity(value),
            ),
          ),
          ListTile(
            title: const Text('Country'),
            subtitle: Text(
              '${CountryOption.flagFromCode(settings.countryCode)} ${settings.country}\n${settings.timezone}',
            ),
            onTap: () async {
              final selected = await context.push<CountryOption>(
                AppRoutes.countrySelection,
              );
              if (selected == null || !context.mounted) {
                return;
              }
              await ref
                  .read(settingsControllerProvider.notifier)
                  .applyCountry(selected);
            },
          ),
          ListTile(
            title: const Text('Timezone'),
            subtitle: Text(settings.timezone),
            onTap: null,
          ),
          ListTile(
            title: const Text('Profile Name'),
            subtitle: Text(settings.profileName),
            onTap: () => _prompt(
              context,
              title: 'Update Profile Name',
              initialValue: settings.profileName,
              onSubmit: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setProfileName(value),
            ),
          ),
          ListTile(
            title: const Text('Profile Email (optional)'),
            subtitle: Text(
              settings.profileEmail.isEmpty ? 'Not set' : settings.profileEmail,
            ),
            onTap: () => _prompt(
              context,
              title: 'Update Profile Email',
              initialValue: settings.profileEmail,
              onSubmit: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setProfileEmail(value),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Prayer Calculation Method'),
            subtitle: Text('Method ID: ${settings.prayerMethod}'),
            trailing: DropdownButton<int>(
              value: settings.prayerMethod,
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(settingsControllerProvider.notifier)
                    .setPrayerMethod(value);
              },
              items: const [
                DropdownMenuItem(value: 1, child: Text('Karachi (1)')),
                DropdownMenuItem(value: 2, child: Text('ISNA (2)')),
                DropdownMenuItem(value: 3, child: Text('MWL (3)')),
                DropdownMenuItem(value: 4, child: Text('Umm Al-Qura (4)')),
                DropdownMenuItem(value: 5, child: Text('Egyptian (5)')),
                DropdownMenuItem(value: 11, child: Text('MUIS Singapore (11)')),
                DropdownMenuItem(value: 13, child: Text('Diyanet Turkey (13)')),
                DropdownMenuItem(value: 15, child: Text('Moonsighting Committee (15)')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Madhhab'),
            subtitle: Text(settings.madhhab),
            trailing: DropdownButton<String>(
              value: settings.madhhab,
              onChanged: (value) {
                if (value == null) return;
                ref.read(settingsControllerProvider.notifier).setMadhhab(value);
              },
              items: const [
                DropdownMenuItem(value: 'Shafi', child: Text('Shafi')),
                DropdownMenuItem(value: 'Hanafi', child: Text('Hanafi')),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Azan Enabled'),
            value: settings.azanEnabled,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setAzanEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: settings.vibrationEnabled,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setVibrationEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Silent notification mode'),
            value: settings.silentMode,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setSilentMode(value),
          ),
          ListTile(
            title: const Text('Muazzin Voice'),
            subtitle: Text(settings.muazzinVoice),
            trailing: DropdownButton<String>(
              value: settings.muazzinVoice,
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(settingsControllerProvider.notifier)
                    .setMuazzinVoice(value);
              },
              items: const [
                DropdownMenuItem(value: 'Makkah', child: Text('Makkah')),
                DropdownMenuItem(value: 'Madinah', child: Text('Madinah')),
                DropdownMenuItem(value: 'Alafasy', child: Text('Alafasy')),
              ],
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Per-prayer notifications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (final prayer in const [
            'Fajr',
            'Dhuhr',
            'Asr',
            'Maghrib',
            'Isha',
          ])
            SwitchListTile(
              title: Text(prayer),
              value: settings.perPrayerNotifications[prayer] ?? true,
              onChanged: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setPrayerNotificationEnabled(prayer, value),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _prompt(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSubmit,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await onSubmit(value);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
