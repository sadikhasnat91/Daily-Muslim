import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/settings/domain/app_settings.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  group('prayer calculation engine', () {
    test('should calculate different seasonal times for the same city', () {
      final january = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 1, 15),
        settings: const AppSettings(
          themeMode: ThemeMode.dark,
          notificationsEnabled: true,
          city: 'Dhaka',
          country: 'Bangladesh',
          countryCode: 'BD',
          timezone: 'Asia/Dhaka',
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
          latitude: 23.8103,
          longitude: 90.4125,
        ),
      );

      final july = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 7, 15),
        settings: const AppSettings(
          themeMode: ThemeMode.dark,
          notificationsEnabled: true,
          city: 'Dhaka',
          country: 'Bangladesh',
          countryCode: 'BD',
          timezone: 'Asia/Dhaka',
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
          latitude: 23.8103,
          longitude: 90.4125,
        ),
      );

      expect(
        january.prayers.first.time,
        isNot(equals(july.prayers.first.time)),
      );
      expect(january.prayers[1].time, isNot(equals(july.prayers[1].time)));
    });

    test(
      'should order prayer times chronologically and bind until boundaries',
      () {
        final day = PrayerRepository.calculatePrayerDayForSettings(
          date: DateTime(2026, 4, 15),
          settings: const AppSettings(
            themeMode: ThemeMode.dark,
            notificationsEnabled: true,
            city: 'Makkah',
            country: 'Saudi Arabia',
            countryCode: 'SA',
            timezone: 'Asia/Riyadh',
            profileName: '',
            profileEmail: '',
            profileImageUrl: '',
            onboardingComplete: false,
            prayerMethod: 4,
            madhhab: 'Shafi',
            azanEnabled: true,
            vibrationEnabled: true,
            silentMode: false,
            muazzinVoice: 'Makkah',
            perPrayerNotifications: AppSettings.defaultPerPrayerNotifications,
            latitude: 21.4225,
            longitude: 39.8262,
          ),
        );

        final times = day.prayers.map((entry) => entry.time).toList();
        expect(times[0].isBefore(times[1]), isTrue);
        expect(times[1].isBefore(times[2]), isTrue);
        expect(times[2].isBefore(times[3]), isTrue);
        expect(times[3].isBefore(times[4]), isTrue);
        expect(day.sunrise.isAfter(times[0]), isTrue);
        expect(day.sunrise.isBefore(times[1]), isTrue);
      },
    );

    test('should convert prayer times into the selected city timezone', () {
      final day = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 8, 8),
        settings: const AppSettings(
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
        ),
      );

      final cityNow = tz.TZDateTime.from(
        day.prayers.first.time,
        tz.getLocation('Asia/Kuala_Lumpur'),
      );
      expect(day.prayers.first.time.timeZoneOffset.inHours, equals(8));
      expect(cityNow.hour, greaterThan(4));
      expect(cityNow.hour, lessThan(8));
      expect(day.prayers[1].time.isAfter(day.prayers.first.time), isTrue);
    });
  });
}
