// app_theme_tokens.dart
//
// Single source of truth for design tokens, shared UI components, and
// responsive helpers used by every screen in the Muslim Daily app.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/navigation/ui_actions.dart';

// ---------------------------------------------------------------------------
// Design tokens – colours
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static const surface = Color(0xFF0E1511);
  static const tertiaryContainer = Color(0xFFFC7C78);
  static const secondary = Color(0xFF8BD6B6);
  static const onBackground = Color(0xFFDDE4DD);
  static const primary = Color(0xFF4EDEA3);
  static const surfaceVariant = Color(0xFF2F3632);
  static const surfaceContainer = Color(0xFF1A211D);
  static const surfaceContainerHigh = Color(0xFF242C27);
  static const onSurface = Color(0xFFDDE4DD);
  static const onSurfaceVariant = Color(0xFFBBCABF);
  static const background = Color(0xFF0E1511);
  static const error = Color(0xFFFFB4AB);
  static const onPrimary = Color(0xFF003824);
}

// ---------------------------------------------------------------------------
// Design tokens – spacing
// ---------------------------------------------------------------------------
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 12.0;
  static const base = 8.0;
  static const gutter = 16.0;
  static const md = 24.0;
  static const lg = 40.0;
  static const xl = 64.0;

  /// Horizontal page margin on mobile (< 600 dp).
  static const marginMobile = 20.0;

  /// Horizontal page margin on tablet/desktop (>= 600 dp).
  static const marginDesktop = 48.0;
}

// ---------------------------------------------------------------------------
// Responsive breakpoint helpers
// ---------------------------------------------------------------------------
class AppResponsive {
  AppResponsive._();

  /// Small phone: width < 360 dp.
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  /// Phone: width < 600 dp.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Tablet: 600 ≤ width < 900 dp.
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 900;
  }

  /// Desktop/large: width >= 900 dp.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// True for either tablet or desktop.
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Horizontal page margin (adapts to screen width).
  static double horizontalMargin(BuildContext context) =>
      isWide(context) ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

  /// Scale a font size linearly between [min] and [max] based on screen width
  /// (mapped from 320 dp → [min], 480 dp → [max], clamped beyond).
  static double scaleFont(
    BuildContext context, {
    required double min,
    required double max,
  }) {
    final w = MediaQuery.of(context).size.width.clamp(320.0, 480.0);
    final t = (w - 320) / (480 - 320); // 0..1
    return (min + (max - min) * t).roundToDouble();
  }

  /// Bottom scroll padding: 112 on mobile (nav bar), 32 on wide.
  static double bottomScrollPad(BuildContext context) =>
      isWide(context) ? 32 : 112;
}

// ---------------------------------------------------------------------------
// Reusable glass-morphism surface
// ---------------------------------------------------------------------------
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 24,
    this.tint = const Color(0x992F3632),
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final double blurSigma;
  final Color tint;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bottom navigation bar (mobile only)
// ---------------------------------------------------------------------------

/// Which tab is currently active.
enum NavTab { home, prayer, quran, duas, profile }

class SharedBottomNavBar extends StatelessWidget {
  const SharedBottomNavBar({super.key, required this.active});

  final NavTab active;

  static const _items = [
    (icon: Icons.home, label: 'Home', tab: NavTab.home),
    (icon: Icons.schedule, label: 'Prayer', tab: NavTab.prayer),
    (icon: Icons.menu_book, label: 'Quran', tab: NavTab.quran),
    (icon: Icons.auto_awesome, label: 'Duas', tab: NavTab.duas),
    (icon: Icons.person, label: 'Profile', tab: NavTab.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: GlassSurface(
        blurSigma: 24,
        tint: AppColors.surface.withOpacity(0.6),
        border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16),
        ],
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final item in _items)
                  _NavItem(
                    icon: item.icon,
                    label: item.label,
                    active: item.tab == active,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withOpacity(0.7);

    return InkWell(
      onTap: () => UiActions.openByLabel(context, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 0.55,
                color: color,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared profile-aware top app bar
// ---------------------------------------------------------------------------
class SharedTopAppBar extends StatelessWidget {
  const SharedTopAppBar({
    super.key,
    required this.profileName,
    required this.profileImageUrl,
    this.scrollOpacity = 0.6,
    this.showGreeting = true,
  });

  final String profileName;
  final String profileImageUrl;

  /// 0.6 = default, 0.8 = scrolled. Pass a reactive value.
  final double scrollOpacity;

  /// If false, shows only the avatar (compact header).
  final bool showGreeting;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        profileImageUrl.startsWith('http://') ||
        profileImageUrl.startsWith('https://');
    final initials = profileName.trim().isEmpty
        ? 'M'
        : profileName.trim().substring(0, 1).toUpperCase();
    final isSmall = AppResponsive.isSmall(context);

    return GlassSurface(
      blurSigma: 24,
      tint: AppColors.surface.withOpacity(scrollOpacity),
      border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalMargin(context),
            vertical: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isSmall ? 16 : 20,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage:
                          hasImage ? NetworkImage(profileImageUrl) : null,
                      child: hasImage
                          ? null
                          : Text(
                              initials,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                    ),
                    if (showGreeting) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Assalamualikum, $profileName',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: AppResponsive.scaleFont(
                              context,
                              min: 16,
                              max: 22,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => UiActions.openNotifications(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.onSurfaceVariant,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
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
      ),
    );
  }
}
