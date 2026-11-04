import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/UI/Dua.dart';
import 'package:islam/UI/Prayer%20Times.dart';
import 'package:islam/UI/Quran%20Browser.dart';
import 'package:islam/UI/Quran%20Reader.dart';
import 'package:islam/UI/home%20&%20dashbord.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/features/calendar/presentation/islamic_calendar_screen.dart';
import 'package:islam/features/notifications/presentation/notifications_screen.dart';
import 'package:islam/features/location/presentation/country_selection_screen.dart';
import 'package:islam/features/onboarding/presentation/onboarding_screen.dart';
import 'package:islam/features/prayer/presentation/prayer_tracker_screen.dart';
import 'package:islam/features/profile/presentation/profile_screen.dart';
import 'package:islam/features/qibla/presentation/qibla_screen.dart';
import 'package:islam/features/search/presentation/search_screen.dart';
import 'package:islam/features/settings/presentation/settings_screen.dart';
import 'package:islam/features/splash/presentation/splash_screen.dart';
import 'package:islam/features/tasbih/presentation/tasbih_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

String _initialLocation() {
  return AppRoutes.splash;
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: _initialLocation(),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: AppRoutes.prayerTimes,
      builder: (_, __) => const PrayerTimesScreen(),
    ),
    GoRoute(
      path: AppRoutes.quranBrowser,
      builder: (_, __) => const QuranBrowserScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.quranReader}/:surahId',
      builder: (_, state) {
        final surahId =
            int.tryParse(state.pathParameters['surahId'] ?? '') ?? 1;
        return QuranReaderScreen(surahId: surahId);
      },
    ),
    GoRoute(path: AppRoutes.duas, builder: (_, __) => const DuasScreen()),
    GoRoute(path: AppRoutes.qibla, builder: (_, __) => const QiblaScreen()),
    GoRoute(
      path: AppRoutes.calendar,
      builder: (_, __) => const IslamicCalendarScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(path: AppRoutes.tasbih, builder: (_, __) => const TasbihScreen()),
    GoRoute(
      path: AppRoutes.prayerTracker,
      builder: (_, __) => const PrayerTrackerScreen(),
    ),
    GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
    GoRoute(
      path: AppRoutes.countrySelection,
      builder: (_, __) => const CountrySelectionScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Route not found: ${state.uri}'),
        ),
      ),
    );
  },
);
