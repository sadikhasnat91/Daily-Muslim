import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final raw = HiveService.instance.settingsBox.get(HiveKeys.appSettings)
        as Map<dynamic, dynamic>?;
    final onboardingComplete = (raw?['onboardingComplete'] as bool?) ?? false;

    if (mounted) {
      context.go(onboardingComplete ? AppRoutes.home : AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtmosphericBackground(
        child: Stack(
          children: [
            // Center Animated 3D Content
            Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Center(
                  child: AnimatedBuilder(
              animation: Listenable.merge([_entranceController, _pulseController]),
              builder: (context, child) {
                final pulse = _pulseController.value;
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 3D Dimensional Medallion with pulsing aura
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.25 + 0.1 * pulse),
                                Colors.transparent,
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF1B3829), Color(0xFF0F1E16)],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3 + 0.15 * pulse),
                                    blurRadius: 28 + 10 * pulse,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    offset: const Offset(0, 14),
                                    blurRadius: 24,
                                    spreadRadius: -4,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.25),
                                    offset: const Offset(0, -2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating subtle Islamic geometric star
                                  Transform.rotate(
                                    angle: pulse * math.pi * 0.1,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 70,
                                      color: AppColors.gold.withOpacity(0.25),
                                    ),
                                  ),
                                  // 3D Crescent & Star
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppColors.primaryGradient.createShader(bounds),
                                    child: const Icon(
                                      Icons.mosque_rounded,
                                      size: 54,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Title with Slide Animation
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFF7DE3B8),
                                    Color(0xFF00E599),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'DAILY MUSLIM',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your Daily Spiritual Sanctuary',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),

          // Bottom sleek progress indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
