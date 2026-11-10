// notifications_screen.dart
//
// Muslim Daily – World-Class 3D Animated Notifications Center.
// Azan and daily prayer alerts configuration, system permission status, and tactile switches.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications & Alerts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glow
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
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // 3D Master Notification Card
                    Card3D(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E382A), Color(0xFF102218)],
                      ),
                      glowColor: AppColors.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: AppColors.onPrimary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Prayer Reminders',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onBackground,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fajr, Dhuhr, Asr, Maghrib, and Isha notifications',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: settings.notificationsEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (value) => ref
                                    .read(settingsControllerProvider.notifier)
                                    .setNotifications(value),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Permission Status Card
                    Card3D(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Permissions Active',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configured for exact alarm timing and background azan audio.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'PER-PRAYER NOTIFICATION ALERTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3D List of Per-Prayer Toggles
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
                            if (prayer != 'Isha')
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.06),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
