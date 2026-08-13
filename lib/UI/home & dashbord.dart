// home_screen.dart
//
// Muslim Daily – Home / Dashboard screen.
// Responsive for phone, tablet, and desktop.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:islam/features/settings/domain/app_settings.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';

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
    if (now.isBefore(window.start)) {
      return window;
    }
  }
  return windows.isNotEmpty ? windows.last : null;
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
      duration: const Duration(milliseconds: 600),
    );
    _ringProgress = Tween<double>(
      begin: 0,
      end: 0.66,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ringController.forward();
    });
    _loadPrayerTimes();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    final fallbackDay = PrayerRepository.calculatePrayerDayForSettings(
      date: now,
      settings: AppSettings.defaults,
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
          previous.madhhab != next.madhhab) {
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
          // Ambient background glow
          const Positioned.fill(child: _AmbientBackground()),

          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalMargin(context),
                96,
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
                      const SizedBox(height: AppSpacing.lg),
                      _NextPrayerCard(
                        isWide: isWide,
                        progress: _ringProgress,
                        now: now,
                        prayerTimes: prayerTimes,
                        sunrise: _prayerDayData?.sunrise,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _TodayPrayersList(
                        prayerTimes: prayerTimes,
                        now: now,
                        sunrise: _prayerDayData?.sunrise,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _QuickActionsGrid(),
                      const SizedBox(height: AppSpacing.lg),
                      _DualBentoCards(isWide: isWide),
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
            child: SharedTopAppBar(
              profileName: profileName,
              profileImageUrl: profileImageUrl,
            ),
          ),

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
// Ambient background glow blobs
// ---------------------------------------------------------------------------
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.25,
              child: _GlowBlob(
                diameter: size.width * 0.9,
                color: AppColors.primary.withOpacity(0.10),
                blurSigma: 120,
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.25,
              child: _GlowBlob(
                diameter: size.width * 0.6,
                color: AppColors.primary.withOpacity(0.05),
                blurSigma: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double diameter;
  final Color color;
  final double blurSigma;

  const _GlowBlob({
    required this.diameter,
    required this.color,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date header
// ---------------------------------------------------------------------------
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.dayData, required this.now});

  final PrayerDayData? dayData;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayData?.hijriLabel.isNotEmpty == true
                ? dayData!.hijriLabel
                : 'Hijri date loading...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dayData?.gregorianLabel.isNotEmpty == true
                ? dayData!.gregorianLabel
                : DateFormat('EEEE, MMMM d, yyyy').format(now),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next prayer card with circular countdown ring
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

    final windows = buildPrayerWindows(safePrayerTimes, sunrise: sunrise);
    final currentWindow = currentPrayerWindow(now, windows) ?? windows.first;

    final currentPrayer = (currentWindow.name, currentWindow.start);
    final nextBoundary = currentWindow.end;
    final remaining = nextBoundary.difference(now);
    final remainingHours = remaining.inHours;
    final remainingMinutes = remaining.inMinutes.remainder(60);

    // Responsive font sizes
    final prayerNameSize = AppResponsive.scaleFont(context, min: 32, max: 48);
    final timeSubtitleSize = AppResponsive.scaleFont(context, min: 14, max: 18);
    // Ring size: smaller on compact phones
    final ringSize = AppResponsive.isSmall(context) ? 120.0 : 160.0;

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_twilight, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'CURRENT PRAYER',
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 0.65,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          currentPrayer.$1,
          style: GoogleFonts.inter(
            fontSize: prayerNameSize,
            height: 1.17,
            letterSpacing: -0.96,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${DateFormat('h:mm a').format(currentPrayer.$2)} → '
          '${DateFormat('h:mm a').format(nextBoundary)} • Ends in '
          '${remainingHours}h ${remainingMinutes}m',
          style: GoogleFonts.inter(
            fontSize: timeSubtitleSize,
            color: AppColors.onSurfaceVariant,
          ),
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
            painter: _ProgressRingPainter(progress: progress.value),
            child: Center(
              child: Text(
                '${remaining.inHours.toString().padLeft(2, '0')}:'
                '${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: AppResponsive.scaleFont(context, min: 22, max: 32),
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );

    return GlassSurface(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Decorative gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWide ? AppSpacing.lg : AppSpacing.md),
            child: isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: infoColumn),
                      ring,
                    ],
                  )
                : Column(
                    children: [
                      Align(alignment: Alignment.centerLeft, child: infoColumn),
                      const SizedBox(height: AppSpacing.md),
                      ring,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Paints the circular countdown ring.
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 6) / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

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
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Quick actions grid (5 icon buttons)
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    (icon: Icons.schedule, label: 'Prayers'),
    (icon: Icons.explore, label: 'Qibla'),
    (icon: Icons.fiber_manual_record, label: 'Tasbih'),
    (icon: Icons.auto_awesome, label: 'Duas'),
    (icon: Icons.calendar_month, label: 'Calendar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final action in _actions)
          Expanded(
            child: _QuickActionButton(icon: action.icon, label: action.label),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isSmall = AppResponsive.isSmall(context);
    final iconBoxSize = isSmall ? 40.0 : 48.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => UiActions.openByLabel(context, label),
        hoverColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: isSmall ? 2 : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassSurface(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  child: Icon(
                    icon,
                    size: isSmall ? 20 : 24,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 10 : 13,
                  letterSpacing: 0.65,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's prayers list (horizontal scroll)
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Today's Prayers (Waqt)",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(prayerTimes.length, (index) {
              final prayer = prayerTimes[index];
              final windows = buildPrayerWindows(prayerTimes, sunrise: sunrise);
              final currentWindow = windows[index];
              final endTime = currentWindow.end;

              final isCurrent = now.isAfter(prayer.$2) && now.isBefore(endTime);
              final isPast = now.isAfter(endTime);

              return Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.$1,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isPast
                                ? AppColors.onSurfaceVariant.withOpacity(0.5)
                                : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${DateFormat('h:mm a').format(prayer.$2)}\nuntil ${DateFormat('h:mm a').format(endTime)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: isPast
                                ? AppColors.onSurfaceVariant.withOpacity(0.5)
                                : AppColors.onSurfaceVariant,
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
// Dual bento cards: Daily Ayah + Continue Reading
// ---------------------------------------------------------------------------
class _DualBentoCards extends StatelessWidget {
  final bool isWide;
  const _DualBentoCards({required this.isWide});

  @override
  Widget build(BuildContext context) {
    const ayah = _DailyAyahCard();
    const continueReading = _ContinueReadingCard();

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: ayah),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: continueReading),
        ],
      );
    }
    return const Column(
      children: [
        ayah,
        SizedBox(height: AppSpacing.md),
        continueReading,
      ],
    );
  }
}

class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard();

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = AppResponsive.scaleFont(context, min: 26, max: 36);

    return GlassSurface(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Ayah',
                  style: GoogleFonts.inter(
                    fontSize: AppResponsive.scaleFont(
                      context,
                      min: 18,
                      max: 24,
                    ),
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Row(
                  children: [
                    _SmallIconButton(icon: Icons.bookmark_border),
                    const SizedBox(width: 4),
                    _SmallIconButton(icon: Icons.share),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
                textAlign: TextAlign.right,
                style: GoogleFonts.libreCaslonText(
                  fontSize: arabicFontSize,
                  height: 1.6,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Text(
                '"And when My servants ask you concerning Me, indeed I am near."',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Al-Baqarah 2:186',
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 0.65,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  const _SmallIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (icon == Icons.bookmark_border) {
            UiActions.bookmarkAyah(
              context,
              key: 'daily_ayah',
              title: 'Daily Ayah',
              arabic: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
            );
            return;
          }
          UiActions.shareText(
            context,
            'And when My servants ask you concerning Me, indeed I am near. '
            '(Al-Baqarah 2:186)',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        ),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => UiActions.openQuranReader(context, surahId: recentId),
        hoverColor: Colors.white.withOpacity(0.05),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative background ornament
              Positioned(
                top: -16,
                right: -16,
                child: Icon(
                  Icons.menu_book,
                  size: 120,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Reading',
                      style: GoogleFonts.inter(
                        fontSize: AppResponsive.scaleFont(
                          context,
                          min: 18,
                          max: 24,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surah $recentName',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    // Use Spacer to flexibly push the progress to the bottom
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ayah $displayVerse / $recentVerses',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            letterSpacing: 0.65,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            letterSpacing: 0.65,
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
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
