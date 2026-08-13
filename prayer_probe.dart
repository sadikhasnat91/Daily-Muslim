import 'package:adhan_dart/adhan_dart.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';

void main() {
  final settings = const AppSettings(
    themeMode: ThemeMode.dark,
    notificationsEnabled: true,
    city: 'Johor Bahru',
    country: 'Malaysia',
    countryCode: 'MY',
    timezone: 'Asia/Kuala_Lumpur',
    profileName: '',
    profileEmail: '',
    profileImageUrl: '',
    onboardingComplete: false,
    prayerMethod: 1,
    madhhab: 'Shafi',
    azanEnabled: true,
    vibrationEnabled: true,
    silentMode: false,
    muazzinVoice: 'Makkah',
    perPrayerNotifications: AppSettings.defaultPerPrayerNotifications,
    latitude: 1.4927,
    longitude: 103.7414,
  );

  final now = DateTime(2026, 8, 8, 11, 0, 0);
  final day = PrayerRepository.calculatePrayerDayForSettings(date: now, settings: settings);
  for (final p in day.prayers) {
    print('${p.name}: ${p.time}   local=${p.time.toLocal()}');
  }
  print('now local=${now.toLocal()} utc=${now.toUtc()}');
}
