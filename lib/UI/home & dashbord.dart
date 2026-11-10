// home_screen.dart
//
// Muslim Daily – World-Class 3D Animated Home / Dashboard screen.
// Responsive for phone, tablet, and desktop with Apple-grade polish.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/presentation/district_selection_sheet.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class PrayerWindow {
  const PrayerWindow({
    required this.name,
    required this.start,
    required this.end,
  });

  final String name;
  final DateTime start;
  final DateTime end;
}

List<PrayerWindow> buildPrayerWindows(
  List<(String, DateTime)> prayerTimes, {
  DateTime? sunrise,
}) {
  final windows = <PrayerWindow>[];
  for (var index = 0; index < prayerTimes.length; index++) {
    final prayer = prayerTimes[index];
    DateTime endTime;
    if (prayer.$1 == 'Fajr' && sunrise != null) {
      endTime = sunrise;
    } else if (index < prayerTimes.length - 1) {
      endTime = prayerTimes[index + 1].$2;
    } else {
      endTime = prayerTimes.first.$2.add(const Duration(days: 1));
    }
    windows.add(PrayerWindow(name: prayer.$1, start: prayer.$2, end: endTime));
  }
  return windows;
}

PrayerWindow? currentPrayerWindow(DateTime now, List<PrayerWindow> windows) {
  for (final window in windows) {
    if (!now.isBefore(window.start) && now.isBefore(window.end)) {
      return window;
    }
  }
  return null;
}

class ActivePrayerState {
  const ActivePrayerState({
    required this.isCurrent,
    required this.name,
    required this.targetTime,
    required this.subtitle,
    required this.remaining,
  });

  final bool isCurrent;
  final String name;
  final DateTime targetTime;
  final String subtitle;
  final Duration remaining;
}

ActivePrayerState resolveActivePrayerState(
  DateTime now,
  List<(String, DateTime)> prayerTimes, {
  DateTime? sunrise,
}) {
  if (prayerTimes.isEmpty) {
    return ActivePrayerState(
      isCurrent: false,
      name: 'Fajr',
      targetTime: now.add(const Duration(hours: 1)),
      subtitle: 'Calculating...',
      remaining: const Duration(hours: 1),
    );
  }

  final windows = buildPrayerWindows(prayerTimes, sunrise: sunrise);

  for (final window in windows) {
    if (!now.isBefore(window.start) && now.isBefore(window.end)) {
      final rem = window.end.difference(now);
      final h = rem.inHours;
      final m = rem.inMinutes.remainder(60);
      return ActivePrayerState(
        isCurrent: true,
        name: window.name,
        targetTime: window.end,
        subtitle:
            '${DateFormat('h:mm a').format(window.start)} → ${DateFormat('h:mm a').format(window.end)} • Ends in ${h}h ${m}m',
        remaining: rem,
      );
    }
  }

  for (final window in windows) {
    if (now.isBefore(window.start)) {
      final rem = window.start.difference(now);
      final h = rem.inHours;
      final m = rem.inMinutes.remainder(60);
      return ActivePrayerState(
        isCurrent: false,
        name: window.name,
        targetTime: window.start,
        subtitle:
            'Starts at ${DateFormat('h:mm a').format(window.start)} • In ${h}h ${m}m',
        remaining: rem,
      );
    }
  }

  final nextFajr = windows.first.start.add(const Duration(days: 1));
  final rem = nextFajr.difference(now);
  final h = rem.inHours;
  final m = rem.inMinutes.remainder(60);
  return ActivePrayerState(
    isCurrent: false,
    name: 'Fajr',
    targetTime: nextFajr,
    subtitle:
        'Starts tomorrow at ${DateFormat('h:mm a').format(nextFajr)} • In ${h}h ${m}m',
    remaining: rem,
  );
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringProgress;
  Timer? _clockTimer;
  final PrayerRepository _prayerRepository = PrayerRepository(
    HiveService.instance,
  );
  List<PrayerTimeEntry> _prayerTimes = const [];
  PrayerDayData? _prayerDayData;
  DateTime? _lastLoadedDay;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringProgress = Tween<double>(
      begin: 0,
      end: 0.68,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOutBack));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ringController.forward();
    });
    _loadPrayerTimes();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _refreshDailyIfNeeded();
        setState(() {});
      }
    });
  }

  Future<void> _loadPrayerTimes() async {
    final settings = ref.read(settingsControllerProvider);
    final timezoneId = settings.timezone;
    final now = appNowForTimezone(timezoneId);

    final data = await _prayerRepository.getPrayerDayData(now);

    if (!mounted) return;
    setState(() {
      _prayerDayData = data;
      _prayerTimes = data.prayers;
      _lastLoadedDay = DateTime(now.year, now.month, now.day);
    });
  }

  void _refreshDailyIfNeeded() {
    final settings = ref.read(settingsControllerProvider);
    final timezoneId = settings.timezone;
    final now = appNowForTimezone(timezoneId);
    final day = DateTime(now.year, now.month, now.day);
    if (_lastLoadedDay == null || _lastLoadedDay != day) {
      _loadPrayerTimes();
    }
  }

  List<(String, DateTime)> _fallbackPrayerTimes(DateTime now) {
    final settings = ref.read(settingsControllerProvider);
    final fallbackDay = PrayerRepository.calculatePrayerDayForSettings(
      date: now,
      settings: settings,
    );
    return fallbackDay.prayers
        .map((entry) => (entry.name, entry.time))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);
    final settings = ref.watch(settingsControllerProvider);
    final timezoneId = settings.timezone;
    final profileName = settings.profileName.isEmpty ? 'Muslim Daily User' : settings.profileName;
    final profileImageUrl = settings.profileImageUrl;
    final now = appNowForTimezone(timezoneId);

    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous == null ||
          previous.city != next.city ||
          previous.country != next.country ||
          previous.timezone != next.timezone ||
          previous.prayerMethod != next.prayerMethod ||
          previous.madhhab != next.madhhab ||
          previous.latitude != next.latitude ||
          previous.longitude != next.longitude) {
        _loadPrayerTimes();
      }
    });

    final prayerTimes = _prayerTimes.isNotEmpty
        ? _prayerTimes
              .map((item) => (item.name, item.time))
              .toList(growable: false)
        : _fallbackPrayerTimes(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glow Orbs for 3D depth
          Positioned(
            top: -100,
            right: -80,
            child: GlowOrb(color: AppColors.primary, radius: 280, opacity: 0.16),
          ),
          Positioned(
            top: 300,
            left: -120,
            child: GlowOrb(color: AppColors.gold, radius: 240, opacity: 0.08),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 220, opacity: 0.12),
          ),

          // Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalMargin(context),
                94,
                AppResponsive.horizontalMargin(context),
                AppResponsive.bottomScrollPad(context),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateHeader(dayData: _prayerDayData, now: now),
                      const SizedBox(height: 20),
                      _NextPrayerCard(
                        isWide: isWide,
                        progress: _ringProgress,
                        now: now,
                        prayerTimes: prayerTimes,
                        sunrise: _prayerDayData?.sunrise,
                      ),
                      const SizedBox(height: 24),
                      _TodayPrayersList(
                        prayerTimes: prayerTimes,
                        now: now,
                        sunrise: _prayerDayData?.sunrise,
                      ),
                      const SizedBox(height: 24),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 24),
                      _DualBentoCards(isWide: isWide),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SharedTopAppBar(
              profileName: profileName,
              profileImageUrl: profileImageUrl,
            ),
          ),

          // Floating Bottom Navigation Dock (Mobile)
          if (!isWide)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.home),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Date Header with Interactive Location Pill
// ---------------------------------------------------------------------------
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.dayData, required this.now});

  final PrayerDayData? dayData;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cityName = dayData?.city.isNotEmpty == true ? dayData!.city : 'Dhaka';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      dayData?.hijriLabel.isNotEmpty == true
                          ? dayData!.hijriLabel
                          : 'Hijri date loading...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                dayData?.gregorianLabel.isNotEmpty == true
                    ? dayData!.gregorianLabel
                    : DateFormat('EEEE, d MMMM yyyy').format(now),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ScaleButton(
          onTap: () => showDistrictPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    cityName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Hero Next Prayer Card with Animated Dual-Ring Timer
// ---------------------------------------------------------------------------
class _NextPrayerCard extends StatelessWidget {
  final bool isWide;
  final Animation<double> progress;
  final DateTime now;
  final List<(String, DateTime)> prayerTimes;
  final DateTime? sunrise;

  const _NextPrayerCard({
    required this.isWide,
    required this.progress,
    required this.now,
    required this.prayerTimes,
    this.sunrise,
  });

  @override
  Widget build(BuildContext context) {
    final safePrayerTimes = prayerTimes.isEmpty
        ? [('Fajr', now.add(const Duration(hours: 1)))]
        : prayerTimes;

    final activeState = resolveActivePrayerState(now, safePrayerTimes, sunrise: sunrise);
    final remaining = activeState.remaining;
    // Responsive ring: on small phones shrink to fit alongside the info column
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = isWide
        ? 160.0
        : (screenWidth < 380 ? 108.0 : (AppResponsive.isSmall(context) ? 118.0 : 140.0));

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D Status Pill (Current vs Next Waqt)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: activeState.isCurrent
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.gold.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeState.isCurrent
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.gold.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeState.isCurrent ? AppColors.primary : AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: (activeState.isCurrent ? AppColors.primary : AppColors.gold)
                          .withOpacity(0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                activeState.isCurrent ? 'CURRENT WAQT' : 'NEXT WAQT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: activeState.isCurrent ? AppColors.primary : AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Large Prayer Name with subtle gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFDDE7E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            activeState.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: AppResponsive.scaleFont(context, min: 32, max: 46),
              height: 1.1,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          activeState.subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final ring = SizedBox(
      width: ringSize,
      height: ringSize,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          return CustomPaint(
            painter: _ModernProgressRingPainter(
              progress: progress.value,
              isCurrent: activeState.isCurrent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${remaining.inHours.toString().padLeft(2, '0')}:${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: AppResponsive.scaleFont(context, min: 20, max: 32),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  Text(
                    'Remaining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return Card3D(
      borderRadius: 26,
      padding: EdgeInsets.all(isWide ? 28 : 22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF192C23), Color(0xFF0F1A14)],
      ),
      glowColor: activeState.isCurrent ? AppColors.primary : AppColors.gold,
      child: isWide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoColumn),
                ring,
              ],
            )
          : Row(
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 12),
                ring,
              ],
            ),
    );
  }
}

class _ModernProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isCurrent;

  _ModernProgressRingPainter({
    required this.progress,
    required this.isCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 10) / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    canvas.drawCircle(center, radius, trackPaint);

    // Glowing Progress Arc
    final activeColor = isCurrent ? AppColors.primary : AppColors.gold;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          activeColor.withOpacity(0.2),
          activeColor,
        ],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ModernProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isCurrent != isCurrent;
}

// ---------------------------------------------------------------------------
// 3D Quick Actions Grid (Isometric Animated Tiles)
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    (icon: Icons.access_time_filled_rounded, label: 'Prayers', color: Color(0xFF00E599)),
    (icon: Icons.explore_rounded, label: 'Qibla', color: Color(0xFF38BDF8)),
    (icon: Icons.fingerprint_rounded, label: 'Tasbih', color: Color(0xFFFBBF24)),
    (icon: Icons.auto_awesome_rounded, label: 'Duas', color: Color(0xFFA78BFA)),
    (icon: Icons.calendar_month_rounded, label: 'Calendar', color: Color(0xFFF472B6)),
  ];

  @override
  Widget build(BuildContext context) {
    final isSmall = AppResponsive.isSmall(context);
    final hPad = isSmall ? 2.0 : 4.0;
    return Row(
      children: [
        for (final action in _actions)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _QuickActionButton(
                icon: action.icon,
                label: action.label,
                accentColor: action.color,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = AppResponsive.isSmall(context);
    final vPad = isSmall ? 10.0 : 14.0;
    final iconBoxPad = isSmall ? 7.0 : 10.0;
    final iconSize = isSmall ? 18.0 : 22.0;
    return ScaleButton(
      onTap: () => UiActions.openByLabel(context, label),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16231C), Color(0xFF0F1713)],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconBoxPad),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withOpacity(0.25),
                    accentColor.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Today's Prayers List (Horizontal Scroll with Waqt Ranges)
// ---------------------------------------------------------------------------
class _TodayPrayersList extends StatelessWidget {
  final List<(String, DateTime)> prayerTimes;
  final DateTime now;
  final DateTime? sunrise;

  const _TodayPrayersList({
    required this.prayerTimes,
    required this.now,
    this.sunrise,
  });

  @override
  Widget build(BuildContext context) {
    if (prayerTimes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Prayers (Waqt)",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.onBackground,
              ),
            ),
            ScaleButton(
              onTap: () => UiActions.openByLabel(context, 'Prayers'),
              child: Text(
                'Full Schedule →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(prayerTimes.length, (index) {
              final prayer = prayerTimes[index];
              final windows = buildPrayerWindows(prayerTimes, sunrise: sunrise);
              final currentWindow = windows[index];
              final endTime = currentWindow.end;

              final isCurrent = !now.isBefore(prayer.$2) && now.isBefore(endTime);
              final isPast = !now.isBefore(endTime);

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ScaleButton(
                  onTap: () => UiActions.openByLabel(context, 'Prayers'),
                  child: Container(
                    width: 154,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: isCurrent
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E3A2B), Color(0xFF112219)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF14201A), Color(0xFF0E1612)],
                            ),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary.withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                        width: isCurrent ? 1.5 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                offset: const Offset(0, 6),
                                blurRadius: 12,
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                prayer.$1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : isPast
                                          ? AppColors.onSurfaceVariant.withOpacity(0.5)
                                          : AppColors.onBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('h:mm a').format(prayer.$2),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isPast
                                ? AppColors.onSurfaceVariant.withOpacity(0.5)
                                : AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'until ${DateFormat('h:mm a').format(endTime)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Dual Bento Cards (Daily Ayah + Continue Reading)
// ---------------------------------------------------------------------------
class _DualBentoCards extends StatelessWidget {
  final bool isWide;
  const _DualBentoCards({required this.isWide});

  @override
  Widget build(BuildContext context) {
    const ayah = _DailyAyahCard();
    const continueReading = _ContinueReadingCard();

    if (isWide) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ayah),
          SizedBox(width: 20),
          Expanded(child: continueReading),
        ],
      );
    }
    return const Column(
      children: [
        ayah,
        SizedBox(height: 20),
        continueReading,
      ],
    );
  }
}

class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard();

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = AppResponsive.scaleFont(context, min: 24, max: 32);

    return Card3D(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DAILY AYAH',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _SmallIconButton(icon: Icons.bookmark_border_rounded),
                  const SizedBox(width: 6),
                  _SmallIconButton(icon: Icons.share_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: arabicFontSize,
                height: 1.8,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Text(
              '"And when My servants ask you concerning Me, indeed I am near."',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Surah Al-Baqarah 2:186',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  const _SmallIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: () {
        if (icon == Icons.bookmark_border_rounded) {
          UiActions.bookmarkAyah(
            context,
            key: 'daily_ayah',
            title: 'Al-Baqarah',
            arabic: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
            surahId: 2,
            ayahNumber: 186,
          );
          return;
        }
        UiActions.shareText(
          context,
          'And when My servants ask you concerning Me, indeed I am near. '
          '(Al-Baqarah 2:186)',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    final recent = HiveService.instance.recentlyReadBox.get('last') as Map?;
    final recentName = (recent?['name'] as String?) ?? 'Ar-Rahman';
    final recentVerses = (recent?['verses'] as int?) ?? 78;
    final recentId = (recent?['id'] as int?) ?? 55;
    final displayVerse = (recent?['ayahNumber'] as int?) ?? 1;
    final progress = recentVerses > 0 ? (displayVerse / recentVerses) : 0.15;

    return Card3D(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      onTap: () => UiActions.openQuranReader(context, surahId: recentId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CONTINUE READING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Surah $recentName',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verse $displayVerse of $recentVerses completed',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
