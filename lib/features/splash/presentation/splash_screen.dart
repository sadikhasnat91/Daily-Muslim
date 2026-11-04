import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';

/// The very first screen shown when the app launches.
///
/// Displays the branded splash artwork while the app finishes its
/// initialization, then routes the user to onboarding (first launch) or
/// straight to the home dashboard (returning users).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Keep the splash on screen long enough to read/animate, while the rest
    // of the app (Hive, timezone db, notification service) finishes booting
    // in the background via main().
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) {
      return;
    }

    final raw =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings)
            as Map<dynamic, dynamic>?;
    final onboardingComplete = (raw?['onboardingComplete'] as bool?) ?? false;

    context.go(onboardingComplete ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041712),
      body: FadeTransition(
        opacity: _fade,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash_screen.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
