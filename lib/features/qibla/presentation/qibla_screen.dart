import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';
import 'package:islam/core/navigation/ui_actions.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  double _deviceHeading = 0.0; // degrees from north, from sensor
  bool _hasCompassSensor = false;
  bool _checkingPermission = true;

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

    // The needle should rotate so it points at the Qibla direction
    // Rotate the needle by (qiblaBearing - deviceHeading) so it always points to Makkah
    final needleAngle = (qiblaBearing - _deviceHeading) * math.pi / 180.0;

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
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Qibla Direction',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          letterSpacing: -0.96,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasLocation
                            ? 'Facing: ${settings.city}, ${settings.country}'
                            : 'Set your location in settings for accurate Qibla direction.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (_checkingPermission)
                        const Center(child: CircularProgressIndicator())
                      else if (!_hasCompassSensor)
                        // No sensor — still show static calculated compass
                        _buildCompass(qiblaBearing: qiblaBearing, needleAngle: needleAngle, dynamic: false)
                      else
                        _buildCompass(qiblaBearing: qiblaBearing, needleAngle: needleAngle, dynamic: true),

                      const SizedBox(height: 48),

                      // Bearing info card
                      GlassSurface(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                '${qiblaBearing.toStringAsFixed(1)}°',
                                style: GoogleFonts.inter(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Qibla bearing from True North',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              if (_hasCompassSensor) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Device heading: ${_deviceHeading.toStringAsFixed(1)}°',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (!hasLocation)
                                ElevatedButton.icon(
                                  onPressed: () => UiActions.openSettings(context),
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Update Location'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppColors.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _hasCompassSensor
                                              ? 'Rotate your phone until the arrow points to Makkah. The compass updates in real time.'
                                              : 'Your device has no compass sensor. Align the top of your device with True North — the arrow shows the Qibla direction.',
                                          style: GoogleFonts.inter(
                                            color: AppColors.onSurface,
                                            height: 1.5,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SharedTopAppBar(
              profileName: 'Muslim Daily',
              profileImageUrl: '',
            ),
          ),
          if (!isWide)
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                backgroundColor: AppColors.surfaceVariant,
                child: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompass({
    required double qiblaBearing,
    required double needleAngle,
    required bool dynamic,
  }) {
    final rotationAngle = dynamic ? -_deviceHeading * math.pi / 180 : 0.0;

    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceVariant.withOpacity(0.3),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: rotationAngle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // N, S, E, W labels (rotate with the compass face)
              Positioned(top: 10, child: Text('N', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant))),
              Positioned(bottom: 10, child: Text('S', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant))),
              Positioned(right: 15, child: Text('E', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant))),
              Positioned(left: 15, child: Text('W', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant))),

              // Needle (fixed at qiblaBearing relative to the compass face, rotates with the compass face)
              Transform.rotate(
                angle: qiblaBearing * math.pi / 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kaaba icon at tip of needle
                    Text('MAKKAH', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4, left: 0, right: 0,
                            child: Container(height: 2, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Needle line
                    Container(width: 4, height: 80, color: AppColors.primary),
                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // Center dot
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
