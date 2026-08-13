import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';
import 'package:islam/core/navigation/ui_actions.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(prayerTrackerProvider); // Watch to trigger rebuilds on updates
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
      body: Stack(
        children: [
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
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: _avatarColor(name),
                              backgroundImage: hasNetworkImage
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: hasNetworkImage
                                  ? null
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filled(
                                onPressed: () => _editText(
                                  context,
                                  title: 'Profile Image URL',
                                  initialValue: imageUrl,
                                  hintText: 'https://example.com/avatar.jpg',
                                  onSave: (value) => ref
                                      .read(settingsControllerProvider.notifier)
                                      .setProfileImageUrl(value),
                                ),
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Edit profile image URL',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Name'),
                          subtitle: Text(name.isEmpty ? 'Not set' : name),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _editText(
                            context,
                            title: 'Profile Name',
                            initialValue: settings.profileName,
                            hintText: 'Enter your name',
                            onSave: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setProfileName(value),
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('City'),
                          subtitle: Text(settings.city),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _editText(
                            context,
                            title: 'City',
                            initialValue: settings.city,
                            hintText: 'Enter city',
                            onSave: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setCity(value),
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Country'),
                          subtitle: Text(
                            '${CountryOption.flagFromCode(settings.countryCode)} ${settings.country}\n${settings.timezone}',
                          ),
                          trailing: const Icon(Icons.edit),
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
                      ),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Email (optional)'),
                          subtitle: Text(
                            settings.profileEmail.isEmpty
                                ? 'Not set'
                                : settings.profileEmail,
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _editText(
                            context,
                            title: 'Email (optional)',
                            initialValue: settings.profileEmail,
                            hintText: 'you@example.com',
                            onSave: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setProfileEmail(value),
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Profile Image URL'),
                          subtitle: Text(
                            imageUrl.isEmpty ? 'Not set' : imageUrl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.link),
                          onTap: () => _editText(
                            context,
                            title: 'Profile Image URL',
                            initialValue: imageUrl,
                            hintText: 'https://example.com/avatar.jpg',
                            onSave: (value) => ref
                                .read(settingsControllerProvider.notifier)
                                .setProfileImageUrl(value),
                          ),
                        ),
                      ),
                      if (imageUrl.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => ref
                              .read(settingsControllerProvider.notifier)
                              .setProfileImageUrl(''),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove Profile Image'),
                        ),
                      const SizedBox(height: 12),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Prayer Statistics'),
                          subtitle: Text('$prayerStats completed prayer tracker entries'),
                          trailing: const Icon(Icons.insights_outlined),
                          onTap: () => UiActions.openPrayerTracker(context),
                        ),
                      ),
                      Card(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        child: ListTile(
                          title: const Text('Reading Statistics'),
                          subtitle: Text(
                            lastReadAyah > 0
                                ? '$lastReadSurah • Last read ayah $lastReadAyah'
                                : 'No reading activity yet',
                          ),
                          trailing: Text('$bookmarkCount bookmarks'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassSurface(
              blurSigma: 24,
              tint: AppColors.surface.withOpacity(0.6),
              border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.horizontalMargin(context),
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profile',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isWide)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.profile),
            ),
        ],
      ),
    );
  }

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
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                await onSave(value);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
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
    if (list.isEmpty) {
      return 'A';
    }
    if (list.length == 1) {
      return list.first.substring(0, 1).toUpperCase();
    }
    return (list.first.substring(0, 1) + list.last.substring(0, 1))
        .toUpperCase();
  }

  static bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return false;
    }
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Color _avatarColor(String name) {
    final hash = name.trim().isEmpty
        ? 31
        : name.codeUnits.fold<int>(17, (a, b) => a * 31 + b);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.65, 0.55).toColor();
  }
}
