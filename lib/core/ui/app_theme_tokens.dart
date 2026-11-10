// app_theme_tokens.dart
//
// World-class design tokens, 3D presentation components, physics-based micro-interactions,
// and responsive layout helpers for the Daily Muslim application.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/navigation/ui_actions.dart';

// ---------------------------------------------------------------------------
// Design tokens – Colors
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  // Premium obsidian dark canvas
  static const background = Color(0xFF080E0B);
  static const surface = Color(0xFF0E1612);
  static const surfaceContainer = Color(0xFF131D18);
  static const surfaceContainerHigh = Color(0xFF19251F);
  static const surfaceVariant = Color(0xFF223129);

  // Vibrant emerald primary
  static const primary = Color(0xFF00E599);
  static const primaryLight = Color(0xFF4EDEA3);
  static const primaryDark = Color(0xFF059669);
  static const primaryGlow = Color(0x5500E599);
  static const onPrimary = Color(0xFF002E1B);

  // Royal gold accents (Kaaba, Quran highlights, streaks)
  static const gold = Color(0xFFFBBF24);
  static const goldDark = Color(0xFFD97706);
  static const goldGlow = Color(0x44FBBF24);

  // Secondary & Accents
  static const secondary = Color(0xFF7DE3B8);
  static const tertiary = Color(0xFF38BDF8); // celestial blue
  static const tertiaryContainer = Color(0xFFFC7C78);
  static const error = Color(0xFFFF6B6B);

  // Foreground text & icons
  static const onBackground = Color(0xFFEDF5EF);
  static const onSurface = Color(0xFFE2EBE5);
  static const onSurfaceVariant = Color(0xFF9EABA3);
  static const borderLight = Color(0x1FFFFFFF);
  static const borderSubtle = Color(0x0FFFFFFF);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E599), Color(0xFF059669)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15221B), Color(0xFF0D1712)],
  );

  static const heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF183124), Color(0xFF0B1711)],
  );
}

// ---------------------------------------------------------------------------
// Design tokens – Spacing
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

  static const marginMobile = 20.0;
  static const marginDesktop = 48.0;
}

// ---------------------------------------------------------------------------
// Responsive breakpoint helpers
// ---------------------------------------------------------------------------
class AppResponsive {
  AppResponsive._();

  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 900;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  static double horizontalMargin(BuildContext context) =>
      isWide(context) ? AppSpacing.marginDesktop : AppSpacing.marginMobile;

  static double scaleFont(
    BuildContext context, {
    required double min,
    required double max,
  }) {
    final w = MediaQuery.of(context).size.width.clamp(320.0, 480.0);
    final t = (w - 320) / (480 - 320);
    return (min + (max - min) * t).roundToDouble();
  }

  static double bottomScrollPad(BuildContext context) =>
      isWide(context) ? 36 : 116;
}

// ---------------------------------------------------------------------------
// 3D Shadows & Lighting effects
// ---------------------------------------------------------------------------
class AppShadows {
  AppShadows._();

  static List<BoxShadow> subtle3D = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.04),
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> elevated3D = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      offset: const Offset(0, 14),
      blurRadius: 28,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: AppColors.primary.withOpacity(0.06),
      offset: const Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.07),
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> primaryGlow3D = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.35),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.25),
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> goldGlow3D = [
    BoxShadow(
      color: AppColors.gold.withOpacity(0.3),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.2),
      offset: const Offset(0, -1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
}

// ---------------------------------------------------------------------------
// Micro-interaction: Scale down on press (3D spring click feedback)
// ---------------------------------------------------------------------------
class ScaleButton extends StatefulWidget {
  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 140),
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final bool enableHaptic;

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _pressed = false;

  void _handleTapDown(_) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(_) {
    if (_pressed) setState(() => _pressed = false);
  }

  void _handleTapCancel() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Glass Surface with Specular Bevel
// ---------------------------------------------------------------------------
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 20,
    this.tint,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.padding,
    this.gradient,
  });

  final Widget child;
  final double blurSigma;
  final Color? tint;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? AppShadows.subtle3D,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint ?? const Color(0xFF121B16).withOpacity(0.72),
              gradient: gradient,
              borderRadius: effectiveRadius,
              border: border ??
                  Border.all(
                    color: Colors.white.withOpacity(0.09),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Dimensional Card with Specular Top Highlight & Depth
// ---------------------------------------------------------------------------
class Card3D extends StatelessWidget {
  const Card3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.gradient,
    this.onTap,
    this.glowColor,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Color? glowColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16231D), Color(0xFF0F1813)],
            ),
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            offset: const Offset(0, 10),
            blurRadius: 24,
            spreadRadius: -4,
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          // 3D Top specular highlight edge
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            offset: const Offset(0, -1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return ScaleButton(onTap: onTap, child: content);
    }
    return content;
  }
}

// ---------------------------------------------------------------------------
// 3D Tactile Animated Button
// ---------------------------------------------------------------------------
class Button3D extends StatelessWidget {
  const Button3D({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient,
    this.textColor,
    this.height = 54,
    this.borderRadius = 18,
    this.isFullWidth = false,
    this.glowColor,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient? gradient;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final bool isFullWidth;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveGradient = isEnabled
        ? (gradient ?? AppColors.primaryGradient)
        : LinearGradient(
            colors: [
              AppColors.surfaceVariant.withOpacity(0.6),
              AppColors.surfaceContainer,
            ],
          );

    final widgetContent = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: effectiveGradient,
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withOpacity(0.35),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.25),
                  offset: const Offset(0, -1),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor ?? AppColors.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: textColor ?? AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );

    if (!isEnabled) {
      return isFullWidth ? SizedBox(width: double.infinity, child: widgetContent) : widgetContent;
    }

    return ScaleButton(
      onTap: onTap,
      child: isFullWidth
          ? SizedBox(width: double.infinity, child: widgetContent)
          : widgetContent,
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient Glow Orb for Atmospheric Depth
// ---------------------------------------------------------------------------
class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.color,
    this.radius = 240,
    this.opacity = 0.22,
  });

  final Color color;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(opacity * 0.4),
              color.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared 3D Floating Bottom Navigation Bar
// ---------------------------------------------------------------------------
enum NavTab { home, prayer, quran, duas, profile }

class SharedBottomNavBar extends StatelessWidget {
  const SharedBottomNavBar({super.key, required this.active});

  final NavTab active;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home', tab: NavTab.home),
    (icon: Icons.access_time_filled_rounded, label: 'Prayer', tab: NavTab.prayer),
    (icon: Icons.menu_book_rounded, label: 'Quran', tab: NavTab.quran),
    (icon: Icons.auto_awesome_rounded, label: 'Duas', tab: NavTab.duas),
    (icon: Icons.person_rounded, label: 'Profile', tab: NavTab.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                offset: const Offset(0, 12),
                blurRadius: 32,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                offset: const Offset(0, 0),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1712).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
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
    return ScaleButton(
      onTap: () => UiActions.openByLabel(context, label),
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: AppColors.primary,
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
// Shared 3D Profile-Aware Top App Bar
// ---------------------------------------------------------------------------
class SharedTopAppBar extends StatelessWidget {
  const SharedTopAppBar({
    super.key,
    required this.profileName,
    required this.profileImageUrl,
    this.scrollOpacity = 0.7,
    this.showGreeting = true,
  });

  final String profileName;
  final String profileImageUrl;
  final double scrollOpacity;
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalMargin(context),
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(scrollOpacity),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isSmall ? 17 : 20,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          backgroundImage:
                              hasImage ? NetworkImage(profileImageUrl) : null,
                          child: hasImage
                              ? null
                              : Text(
                                  initials,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      if (showGreeting) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Assalamu Alaikum,',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                profileName.isEmpty ? 'Brother / Sister' : profileName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: AppResponsive.scaleFont(
                                    context,
                                    min: 16,
                                    max: 20,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onBackground,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ScaleButton(
                  onTap: () => UiActions.openNotifications(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onSurface,
                          size: 22,
                        ),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
