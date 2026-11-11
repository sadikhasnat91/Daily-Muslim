// qibla_screen.dart
//
// Muslim Daily – World-Class 3D Gyroscope Qibla Compass.
// Precision bearing calculation, real-time sensor damping, 3D Kaaba needle, and alignment indicator.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  double _deviceHeading = 0.0;
  bool _hasCompassSensor = false;
  bool _checkingPermission = true;
  bool _wasAligned = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  Future<void> _initCompass() async {
    final isAvailable = FlutterCompass.events != null;
    if (!isAvailable) {
      if (mounted) setState(() { _checkingPermission = false; _hasCompassSensor = false; });
      return;
    }
    if (mounted) {
      setState(() { _hasCompassSensor = true; _checkingPermission = false; });
    }
    FlutterCompass.events?.listen((event) {
      final heading = event.heading;
      if (heading != null && mounted) {
        setState(() => _deviceHeading = heading);
      }
    });
  }

  double _calculateQiblaBearing(double lat, double lng) {
    const makkahLat = 21.422487;
    const makkahLng = 39.826206;

    final lat1 = lat * math.pi / 180.0;
    final lng1 = lng * math.pi / 180.0;
    final lat2 = makkahLat * math.pi / 180.0;
    final lng2 = makkahLng * math.pi / 180.0;

    final dLng = lng2 - lng1;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    var bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final isWide = AppResponsive.isWide(context);

    final lat = settings.latitude;
    final lng = settings.longitude;
    final hasLocation = lat != 0.0 || lng != 0.0;

    final qiblaBearing = hasLocation ? _calculateQiblaBearing(lat, lng) : 258.0;
    final angleDiff = ((qiblaBearing - _deviceHeading) % 360 + 360) % 360;
    final isAligned = (angleDiff < 4 || angleDiff > 356) && _hasCompassSensor;

    if (isAligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
      _wasAligned = true;
    } else if (!isAligned) {
      _wasAligned = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtmosphericBackground(
        child: Stack(
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Entrance3D(
                          delay: const Duration(milliseconds: 50),
                          child: Row(
                            children: [
                              HoloBadge(
                                label: isAligned ? 'ALIGNED WITH MAKKAH' : 'QIBLA COMPASS',
                                color: isAligned ? AppColors.primary : AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Entrance3D(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'Qibla Direction',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: AppResponsive.scaleFont(context, min: 28, max: 40),
                              letterSpacing: -1.0,
                              fontWeight: FontWeight.w900,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Entrance3D(
                          delay: const Duration(milliseconds: 150),
                          child: Text(
                            hasLocation
                                ? 'Facing Holy Kaaba from ${settings.city}, ${settings.country}'
                                : 'Set your location in settings for exact millimeter bearing.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 3D Compass Instrument
                        Entrance3D(
                          delay: const Duration(milliseconds: 250),
                          child: _checkingPermission
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              : _buildCompass(
                                  qiblaBearing: qiblaBearing,
                                  dynamic: _hasCompassSensor,
                                  isAligned: isAligned,
                                ),
                        ),

                        const SizedBox(height: 36),

                        // 3D Bearing Info Card
                        Entrance3D(
                          delay: const Duration(milliseconds: 350),
                          child: Card3D(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(24),
                            glowColor: isAligned ? AppColors.primary : null,
                            child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '${qiblaBearing.toStringAsFixed(1)}°',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                        color: isAligned ? AppColors.primary : AppColors.gold,
                                      ),
                                    ),
                                    Text(
                                      'Qibla Bearing',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${_deviceHeading.toStringAsFixed(1)}°',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                    Text(
                                      'Device Heading',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isAligned
                                    ? AppColors.primary.withOpacity(0.12)
                                    : AppColors.surfaceContainerHigh.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAligned
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isAligned
                                        ? Icons.verified_rounded
                                        : Icons.explore_rounded,
                                    color: isAligned ? AppColors.primary : AppColors.gold,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isAligned
                                          ? 'Your phone is directly facing the Holy Kaaba! Ready for prayer.'
                                          : _hasCompassSensor
                                              ? 'Rotate your phone until the golden Kaaba needle aligns directly with the top arrow.'
                                              : 'Your device has no compass sensor. Align with True North manually — arrow points to Qibla.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        height: 1.5,
                                        fontWeight: isAligned ? FontWeight.w700 : FontWeight.w500,
                                        color: isAligned ? AppColors.primary : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!hasLocation) ...[
                              const SizedBox(height: 16),
                              Button3D(
                                label: 'Set Location in Settings',
                                icon: Icons.settings_rounded,
                                onTap: () => UiActions.openSettings(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

          // Shared Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SharedTopAppBar(
              profileName: settings.profileName.isEmpty ? 'Muslim Daily' : settings.profileName,
              profileImageUrl: settings.profileImageUrl,
            ),
          ),

          // Back button for mobile
          if (!isWide)
            Positioned(
              bottom: 24,
              left: 20,
              child: ScaleButton(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh.withOpacity(0.9),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  }

  Widget _buildCompass({
    required double qiblaBearing,
    required bool dynamic,
    required bool isAligned,
  }) {
    final rotationAngle = dynamic ? -_deviceHeading * math.pi / 180 : 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final compassSize = (screenWidth - 48).clamp(240.0, 310.0);
    final dialSize = compassSize - 10.0;
    final needleStemHeight = (dialSize * 0.24).clamp(52.0, 72.0);
    final needleBottomSpacer = (dialSize * 0.36).clamp(80.0, 110.0);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3D Concentric Compass Housing
          Container(
            width: compassSize,
            height: compassSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF16251E),
                  const Color(0xFF0C1410),
                ],
                stops: const [0.7, 1.0],
              ),
              border: Border.all(
                color: isAligned
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.14),
                width: isAligned ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  offset: const Offset(0, 18),
                  blurRadius: 36,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: (isAligned ? AppColors.primary : AppColors.gold)
                      .withOpacity(isAligned ? 0.35 : 0.12),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.18),
                  offset: const Offset(0, -2),
                  blurRadius: 0,
                ),
              ],
            ),
          ),

          // Rotating Compass Face with Degree Marks and Cardinal Points
          Transform.rotate(
            angle: rotationAngle,
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom Dial Markings
                  CustomPaint(
                    size: Size(dialSize, dialSize),
                    painter: _CompassDialPainter(),
                  ),

                  // Cardinal Points
                  Positioned(
                    top: 14,
                    child: Text(
                      'N',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    child: Text(
                      'S',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    child: Text(
                      'E',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    child: Text(
                      'W',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // 3D Kaaba Needle Pointer
                  Transform.rotate(
                    angle: qiblaBearing * math.pi / 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Kaaba Icon with golden band
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.5),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 7,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  Icons.navigation_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Needle Stem
                        Container(
                          width: 4,
                          height: needleStemHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFBBF24), Color(0xFF00E599)],
                            ),
                          ),
                        ),
                        SizedBox(height: needleBottomSpacer),
                      ],
                    ),
                  ),

                  // Center Pivot Cap
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 2.5;

    for (var i = 0; i < 360; i += 10) {
      final isMajor = i % 30 == 0;
      final angle = i * math.pi / 180;
      final tickLength = isMajor ? 12.0 : 6.0;

      final start = Offset(
        center.dx + (radius - 20) * math.cos(angle),
        center.dy + (radius - 20) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 20 - tickLength) * math.cos(angle),
        center.dy + (radius - 20 - tickLength) * math.sin(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
