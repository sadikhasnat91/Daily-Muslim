// profile_screen.dart
//
// Muslim Daily – World-Class 3D Animated Profile & Spiritual Insights screen.
// 3D Avatar with ambient halo, Bento stats showcase, profile management, and quick settings.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(prayerTrackerProvider);
    final isWide = AppResponsive.isWide(context);
    final settings = ref.watch(settingsControllerProvider);
    final name = settings.profileName.trim();
    final initials = _initials(name);
    final imageUrl = settings.profileImageUrl.trim();
    final hasNetworkImage = _isValidHttpUrl(imageUrl);
    final prayerStats = HiveService.instance.prayerTrackerBox.values
        .whereType<bool>()
        .where((item) => item)
        .length;
    final recent = HiveService.instance.recentlyReadBox.get('last') as Map?;
    final lastReadSurah = (recent?['name'] as String?) ?? 'Not started';
    final lastReadAyah = (recent?['ayahNumber'] as int?) ?? 0;
    final bookmarkCount = HiveService.instance.bookmarksBox.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtmosphericBackground(
        child: Stack(
          children: [
          // Ambient Glows
          Positioned(
            top: 20,
            left: -60,
            child: GlowOrb(color: AppColors.primary, radius: 260, opacity: 0.14),
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalMargin(context),
                92,
                AppResponsive.horizontalMargin(context),
                AppResponsive.bottomScrollPad(context),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // 3D Avatar Header with Halo
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              backgroundImage: hasNetworkImage
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: hasNetworkImage
                                  ? null
                                  : Text(
                                      initials,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: ScaleButton(
                                onTap: () => _editText(
                                  context,
                                  title: 'Profile Image URL',
                                  initialValue: imageUrl,
                                  hintText: 'https://example.com/avatar.jpg',
                                  onSave: (value) => ref
                                      .read(settingsControllerProvider.notifier)
                                      .setProfileImageUrl(value),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        name.isEmpty ? 'Muslim Daily User' : name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CountryOption.flagFromCode(settings.countryCode)} ${settings.city}, ${settings.country}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 3D Stats Bento Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.primary,
                              label: 'Prayers Logged',
                              value: '$prayerStats',
                              onTap: () => UiActions.openPrayerTracker(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bookmark_rounded,
                              iconColor: AppColors.gold,
                              label: 'Bookmarks',
                              value: '$bookmarkCount',
                              onTap: () => UiActions.openByLabel(context, 'Quran'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Quran Reading Stat Card
                      Card3D(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        onTap: () => UiActions.openByLabel(context, 'Quran'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary.withOpacity(0.15),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.secondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quran Progress',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastReadAyah > 0
                                        ? 'Surah $lastReadSurah (Ayah $lastReadAyah)'
                                        : 'No reading activity yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onBackground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'PERSONAL DETAILS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3D Profile Info Card
                      Card3D(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _ProfileTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Full Name',
                              value: name.isEmpty ? 'Not set' : name,
                              onTap: () => _editText(
                                context,
                                title: 'Update Name',
                                initialValue: name,
                                hintText: 'Enter your name',
                                onSave: (val) => ref
                                    .read(settingsControllerProvider.notifier)
                                    .setProfileName(val),
                              ),
                            ),
                            _tileDivider(),
                            _ProfileTile(
                              icon: Icons.mail_outline_rounded,
                              title: 'Email',
                              value: settings.profileEmail.isEmpty
                                  ? 'Not set'
                                  : settings.profileEmail,
                              onTap: () => _editText(
                                context,
                                title: 'Update Email',
                                initialValue: settings.profileEmail,
                                hintText: 'user@example.com',
                                onSave: (val) => ref
                                    .read(settingsControllerProvider.notifier)
                                    .setProfileEmail(val),
                              ),
                            ),
                            _tileDivider(),
                            _ProfileTile(
                              icon: Icons.settings_outlined,
                              title: 'App Settings',
                              value: 'Calculation method, notifications, audio',
                              onTap: () => UiActions.openSettings(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.horizontalMargin(context),
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        ScaleButton(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            } else {
                              context.go(AppRoutes.home);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'My Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (!isWide)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.profile),
            ),
        ],
      ),
    ),
  );
  }

  static Widget _tileDivider() => Divider(
        height: 1,
        color: Colors.white.withOpacity(0.06),
      );

  static Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
    required Future<void> Function(String value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              hintText: hintText,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                await onSave(value);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
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
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return 'A';
    if (list.length == 1) return list.first.substring(0, 1).toUpperCase();
    return (list.first.substring(0, 1) + list.last.substring(0, 1)).toUpperCase();
  }

  static bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card3D(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: AppColors.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
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
        value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
