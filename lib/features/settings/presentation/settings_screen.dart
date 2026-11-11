// settings_screen.dart
//
// Muslim Daily – World-Class 3D Animated Settings screen.
// Sectioned 3D glass cards, tactile switches, dropdown controls, and dialogs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/notifications/azan_notification_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/location/presentation/district_selection_sheet.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _detectingGps = false;
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    AzanNotificationService.instance.stopAdhanAudio();
    super.dispose();
  }

  Future<void> _handleGpsDetection() async {
    setState(() => _detectingGps = true);
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .detectAndApplyGpsLocation();
    if (!mounted) return;
    setState(() => _detectingGps = false);

    final settings = ref.read(settingsControllerProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS coordinates updated: ${settings.city} (${settings.latitude.toStringAsFixed(3)}°, ${settings.longitude.toStringAsFixed(3)}°)',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get GPS fix. Please ensure location services and permissions are enabled.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleAdhanAudio() async {
    if (_isPlayingAudio) {
      await AzanNotificationService.instance.stopAdhanAudio();
      if (mounted) setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      await AzanNotificationService.instance.playAdhanAudio();
      if (mounted) {
        setState(() {
          _isPlayingAudio = AzanNotificationService.instance.isPlayingAdhan;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: AtmosphericBackground(
        child: Stack(
          children: [
          // Background Glows
          Positioned(
            top: 20,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 240, opacity: 0.12),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Section: Appearance
                    _SectionHeader(title: 'APPEARANCE & THEME'),
                    Card3D(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withOpacity(0.15),
                                      ),
                                      child: const Icon(
                                        Icons.palette_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Theme Mode',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onBackground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<ThemeMode>(
                                value: settings.themeMode,
                                dropdownColor: AppColors.surfaceContainerHigh,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                        child: Text(mode.name.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Location & Profile
                    _SectionHeader(title: 'LOCATION & PROFILE'),
                    Card3D(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.my_location_rounded,
                            title: 'Auto-detect Location (GPS)',
                            subtitle: _detectingGps
                                ? 'Connecting to GPS satellites...'
                                : 'Tap to sync exact coordinates using device GPS',
                            trailing: _detectingGps
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                            onTap: _detectingGps ? null : _handleGpsDetection,
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.map_rounded,
                            title: 'Select District (Bangladesh)',
                            subtitle: 'Choose from all 64 BD districts',
                            onTap: () => showDistrictPicker(context),
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.location_city_rounded,
                            title: 'City',
                            subtitle: '${settings.city} (${settings.latitude.toStringAsFixed(3)}°, ${settings.longitude.toStringAsFixed(3)}°)',
                            onTap: () => _prompt(
                              context,
                              title: 'Update City',
                              initialValue: settings.city,
                              onSubmit: (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setCity(value),
                            ),
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.public_rounded,
                            title: 'Country',
                            subtitle:
                                '${CountryOption.flagFromCode(settings.countryCode)} ${settings.country}',
                            onTap: () async {
                              final selected = await context.push<CountryOption>(
                                AppRoutes.countrySelection,
                              );
                              if (selected == null || !context.mounted) return;
                              await ref
                                  .read(settingsControllerProvider.notifier)
                                  .applyCountry(selected);
                            },
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.schedule_rounded,
                            title: 'Timezone',
                            subtitle: settings.timezone,
                            onTap: null,
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.person_rounded,
                            title: 'Profile Name',
                            subtitle: settings.profileName.isEmpty ? 'Not set' : settings.profileName,
                            onTap: () => _prompt(
                              context,
                              title: 'Update Profile Name',
                              initialValue: settings.profileName,
                              onSubmit: (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setProfileName(value),
                            ),
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.mail_rounded,
                            title: 'Profile Email',
                            subtitle: settings.profileEmail.isEmpty ? 'Not set' : settings.profileEmail,
                            onTap: () => _prompt(
                              context,
                              title: 'Update Profile Email',
                              initialValue: settings.profileEmail,
                              onSubmit: (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setProfileEmail(value),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Calculation Methods
                    _SectionHeader(title: 'PRAYER CALCULATION & FIQH'),
                    Card3D(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold.withOpacity(0.15),
                                      ),
                                      child: const Icon(
                                        Icons.calculate_rounded,
                                        size: 18,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Method',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onBackground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: settings.prayerMethod,
                                dropdownColor: AppColors.surfaceContainerHigh,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                  DropdownMenuItem(value: 15, child: Text('Moonsighting (15)')),
                                ],
                              ),
                            ],
                          ),
                          _divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.secondary.withOpacity(0.15),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        size: 18,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Asr Madhhab',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onBackground,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: settings.madhhab,
                                dropdownColor: AppColors.surfaceContainerHigh,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                onChanged: (value) {
                                  if (value == null) return;
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .setMadhhab(value);
                                },
                                items: const [
                                  DropdownMenuItem(value: 'Shafi', child: Text('Shafi / Standard')),
                                  DropdownMenuItem(value: 'Hanafi', child: Text('Hanafi')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Notifications & Azan
                    _SectionHeader(title: 'NOTIFICATIONS & AZAN'),
                    Card3D(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Prayer Notifications',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                            subtitle: Text(
                              'Daily alerts when waqt starts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            value: settings.notificationsEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setNotifications(value),
                          ),
                          _divider(),
                          SwitchListTile(
                            title: Text(
                              'Azan Sound Alarms',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                            subtitle: Text(
                              'Play audio azan on prayer start',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            value: settings.azanEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setAzanEnabled(value),
                          ),
                          _divider(),
                          SwitchListTile(
                            title: Text(
                              'Vibration',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                            value: settings.vibrationEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setVibrationEnabled(value),
                          ),
                          _divider(),
                          SwitchListTile(
                            title: Text(
                              'Silent Notification Mode',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                            value: settings.silentMode,
                            activeColor: AppColors.primary,
                            onChanged: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setSilentMode(value),
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: Icons.notifications_active_rounded,
                            title: 'Test Notification & Sound',
                            subtitle: 'Trigger a sample prayer alert immediately',
                            trailing: const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            onTap: () async {
                              await ref
                                  .read(settingsControllerProvider.notifier)
                                  .sendTestNotification(testAzan: settings.azanEnabled);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      settings.azanEnabled
                                          ? 'Adhan alarm test triggered! Check notifications.'
                                          : 'Standard notification test triggered! Check notifications.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                          ),
                          _divider(),
                          _SettingsTile(
                            icon: _isPlayingAudio
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                            title: _isPlayingAudio
                                ? 'Stop Adhan Audio'
                                : 'Preview Adhan Audio',
                            subtitle: _isPlayingAudio
                                ? 'Playing full Adhan audio...'
                                : 'Listen to the full Adhan call to prayer',
                            trailing: Icon(
                              _isPlayingAudio
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                              color: _isPlayingAudio
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                            onTap: _toggleAdhanAudio,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section: Per Prayer Toggles
                    _SectionHeader(title: 'PER-PRAYER ALERTS'),
                    Card3D(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (final prayer in const [
                            'Fajr',
                            'Dhuhr',
                            'Asr',
                            'Maghrib',
                            'Isha',
                          ]) ...[
                            SwitchListTile(
                              title: Text(
                                prayer,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              value: settings.perPrayerNotifications[prayer] ?? true,
                              activeColor: AppColors.primary,
                              onChanged: (value) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .setPrayerNotificationEnabled(prayer, value),
                            ),
                            if (prayer != 'Isha') _divider(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  static Widget _divider() => Divider(
        height: 1,
        color: Colors.white.withOpacity(0.06),
      );

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
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(color: AppColors.onBackground),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await onSubmit(value);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceVariant.withOpacity(0.6),
        ),
        child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}
