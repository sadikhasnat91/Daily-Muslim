// tasbih_screen.dart
//
// Muslim Daily – World-Class 3D Physical Digital Tasbih Counter.
// Interactive 3D counter bead, tactile haptic feedback, OLED display, and Dhikr presets.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/tasbih/presentation/tasbih_controller.dart';

class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  int _selectedTarget = 33;
  int _selectedDhikrIndex = 0;

  static const _dhikrList = [
    (arabic: 'سُبْحَانَ ٱللَّٰهِ', translit: 'SubhanAllah', meaning: 'Glory be to Allah'),
    (arabic: 'ٱلْحَمْدُ لِلَّٰهِ', translit: 'Alhamdulillah', meaning: 'Praise be to Allah'),
    (arabic: 'ٱللَّٰهُ أَكْبَرُ', translit: 'Allahu Akbar', meaning: 'Allah is the Greatest'),
    (arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ', translit: 'Astaghfirullah', meaning: 'I seek forgiveness from Allah'),
    (arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ', translit: 'La ilaha illallah', meaning: 'There is no deity except Allah'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onCountPressed() {
    _pulseController.forward(from: 0.0);
    ref.read(tasbihControllerProvider.notifier).increment();
    HapticFeedback.mediumImpact();
  }

  void _onResetPressed() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Counter?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'Are you sure you want to reset your Tasbih count back to 0?',
          style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tasbihControllerProvider.notifier).reset();
              Navigator.of(ctx).pop();
              HapticFeedback.heavyImpact();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Reset',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(tasbihControllerProvider);
    final currentDhikr = _dhikrList[_selectedDhikrIndex];
    final progress = (count % _selectedTarget) / _selectedTarget;
    final completedCycles = count ~/ _selectedTarget;

    // ── Responsive sizes ──────────────────────────────────────────────────────
    final screenWidth = MediaQuery.of(context).size.width;
    final outerRing = (screenWidth * 0.70).clamp(200.0, 270.0);
    final progressRing = (outerRing * 0.925).clamp(185.0, 250.0);
    final innerButton = (outerRing * 0.703).clamp(140.0, 190.0);
    final countFontSize = outerRing < 220 ? 36.0 : 48.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tasbih Counter',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          ScaleButton(
            onTap: _onResetPressed,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: AtmosphericBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dhikr Preset Selector Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_dhikrList.length, (index) {
                            final isSelected = index == _selectedDhikrIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ScaleButton(
                                onTap: () => setState(() => _selectedDhikrIndex = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: isSelected
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: isSelected
                                        ? null
                                        : AppColors.surfaceContainer.withOpacity(0.8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.06),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    _dhikrList[index].translit,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.onPrimary
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Dhikr Display Card
                      Card3D(
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          children: [
                            Text(
                              currentDhikr.arabic,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentDhikr.translit,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentDhikr.meaning,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3D Physical Tasbih Bead Device
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer 3D Beveled Ring
                          Container(
                            width: outerRing,
                            height: outerRing,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF16251E), Color(0xFF0C1410)],
                                stops: [0.6, 1.0],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  offset: const Offset(0, 18),
                                  blurRadius: 36,
                                  spreadRadius: -4,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 30,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.15),
                                  offset: const Offset(0, -2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                          ),

                          // Target Progress Arc
                          SizedBox(
                            width: progressRing,
                            height: progressRing,
                            child: CustomPaint(
                              painter: _TasbihArcPainter(progress: progress),
                            ),
                          ),

                          // Interactive 3D Tactile Center Button
                          ScaleButton(
                            onTap: _onCountPressed,
                            pressedScale: 0.92,
                            child: Container(
                              width: innerButton,
                              height: innerButton,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF1E3A2B), Color(0xFF0F2017)],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(0, 10),
                                    blurRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    offset: const Offset(0, -2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$count',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: countFontSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.5,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${count % _selectedTarget} / $_selectedTarget',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (completedCycles > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'x$completedCycles',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'TAP TO COUNT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurfaceVariant.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Target Switcher (33, 99, 100)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: AppColors.surfaceContainer.withOpacity(0.8),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [33, 99, 100].map((target) {
                            final isSelected = target == _selectedTarget;
                            return Expanded(
                              child: ScaleButton(
                                onTap: () => setState(() => _selectedTarget = target),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.18)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primary.withOpacity(0.35),
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Target: $target',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _TasbihArcPainter extends CustomPainter {
  final double progress;
  _TasbihArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5;
    canvas.drawCircle(center, radius, trackPaint);

    // 33 Physical Misbaha Bead Markers along track
    const totalBeads = 33;
    final activeBeadCount = (progress * totalBeads).round();

    for (var i = 0; i < totalBeads; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / totalBeads);
      final bx = center.dx + radius * math.cos(angle);
      final by = center.dy + radius * math.sin(angle);
      final bPos = Offset(bx, by);

      final isPast = i < activeBeadCount;
      final beadPaint = Paint()
        ..color = isPast
            ? AppColors.primary
            : Colors.white.withOpacity(0.18)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(bPos, (i % 11 == 0) ? 3.5 : 2.2, beadPaint);
    }

    // Glowing Continuous Progress Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.primary.withOpacity(0.2),
          AppColors.primary,
        ],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
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

    // Glowing Lead Bead at Progress Tip
    if (progress > 0.01) {
      final tipAngle = startAngle + sweepAngle;
      final tipPos = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final glowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(tipPos, 8, glowPaint);

      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(tipPos, 3.8, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
