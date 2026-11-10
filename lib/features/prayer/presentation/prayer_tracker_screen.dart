// prayer_tracker_screen.dart
//
// Muslim Daily – World-Class 3D Animated Prayer & Qada Habit Tracker.
// Interactive completion ring, 3D prayer status cards, streak statistics, and tactile toggles.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';

class PrayerTrackerScreen extends ConsumerWidget {
  const PrayerTrackerScreen({super.key});

  IconData _iconForPrayer(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_rounded;
      case 'asr':
        return Icons.wb_cloudy_rounded;
      case 'maghrib':
        return Icons.nights_stay_rounded;
      case 'isha':
        return Icons.bedtime_rounded;
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  String _timeOfDayHint(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return 'Dawn Prayer • Before Sunrise';
      case 'dhuhr':
        return 'Noon Prayer • Midday Sun';
      case 'asr':
        return 'Afternoon Prayer • Late Afternoon';
      case 'maghrib':
        return 'Sunset Prayer • Just After Sunset';
      case 'isha':
        return 'Night Prayer • Dark Night';
      default:
        return 'Daily Obligatory Prayer';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerTrackerProvider);
    final completedCount = state.values.where((done) => done).length;
    final totalCount = state.isNotEmpty ? state.length : 5;
    final completionRatio = totalCount > 0 ? completedCount / totalCount : 0.0;

    final isSmall = AppResponsive.isSmall(context);
    final gaugeSize = isSmall ? 84.0 : 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Prayer Tracker',
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
          // Background Glows
          Positioned(
            top: 20,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 240, opacity: 0.14),
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
                    // 3D Progress Hero Card
                    Card3D(
                      borderRadius: 26,
                      padding: const EdgeInsets.all(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B3226), Color(0xFF0F1E17)],
                      ),
                      glowColor: AppColors.primary,
                      child: Row(
                        children: [
                          // Circular Progress Gauge
                          SizedBox(
                            width: gaugeSize,
                            height: gaugeSize,
                            child: CustomPaint(
                              painter: _PrayerCompletionRingPainter(
                                progress: completionRatio,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$completedCount/$totalCount',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                    Text(
                                      'Done',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  completedCount == totalCount
                                      ? 'All Prayers Completed!'
                                      : 'Today\'s Progress',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isSmall ? 16 : 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: AppColors.onBackground,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  completedCount == totalCount
                                      ? 'Alhamdulillah, you have completed all 5 prayers today.'
                                      : 'Tap each prayer once offered to keep your spiritual consistency.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: isSmall ? 12 : 13,
                                    height: 1.4,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'DAILY PRAYERS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3D Prayer Cards
                    for (final prayer in state.keys) ...[
                      () {
                        final isDone = state[prayer] ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ScaleButton(
                            onTap: () {
                              ref
                                  .read(prayerTrackerProvider.notifier)
                                  .toggle(prayer);
                              HapticFeedback.lightImpact();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isDone
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
                                  color: isDone
                                      ? AppColors.primary.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.08),
                                  width: isDone ? 1.5 : 1,
                                ),
                                boxShadow: isDone
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isDone
                                          ? AppColors.primaryGradient
                                          : null,
                                      color: isDone
                                          ? null
                                          : AppColors.surfaceVariant.withOpacity(0.5),
                                      border: Border.all(
                                        color: isDone
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.white10,
                                      ),
                                    ),
                                    child: Icon(
                                      _iconForPrayer(prayer),
                                      color: isDone
                                          ? AppColors.onPrimary
                                          : AppColors.onSurfaceVariant,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prayer,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: isDone
                                                ? AppColors.primary
                                                : AppColors.onBackground,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _timeOfDayHint(prayer),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isDone
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant.withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: isDone
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.5),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isDone
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: AppColors.onPrimary,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }(),
                    ],
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

class _PrayerCompletionRingPainter extends CustomPainter {
  final double progress;
  _PrayerCompletionRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary,
          ],
          stops: const [0.0, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
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
  }

  @override
  bool shouldRepaint(covariant _PrayerCompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
