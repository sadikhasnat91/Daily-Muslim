import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/location/data/bd_districts.dart';
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

    test('should auto-recover Dhaka coordinates and calculate accurate Bangladesh times when coordinates are (0, 0)', () {
      final day = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 11, 4),
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
          onboardingComplete: true,
          prayerMethod: 1,
          madhhab: 'Hanafi',
          azanEnabled: true,
          vibrationEnabled: true,
          silentMode: false,
          muazzinVoice: 'Makkah',
          perPrayerNotifications: AppSettings.defaultPerPrayerNotifications,
          latitude: 0.0,
          longitude: 0.0,
        ),
      );

      final fajr = day.prayers.firstWhere((p) => p.name == 'Fajr').time;
      final dhuhr = day.prayers.firstWhere((p) => p.name == 'Dhuhr').time;
      final asr = day.prayers.firstWhere((p) => p.name == 'Asr').time;
      final maghrib = day.prayers.firstWhere((p) => p.name == 'Maghrib').time;
      final isha = day.prayers.firstWhere((p) => p.name == 'Isha').time;

      // In Dhaka, Bangladesh on Nov 4:
      // Fajr is early morning around 4:40 - 5:00 AM (NOT 10:29 AM!)
      expect(fajr.hour, equals(4));
      // Dhuhr is around 11:40 AM (NOT 5:45 PM!)
      expect(dhuhr.hour, equals(11));
      // Asr is around 3:30 - 4:15 PM (NOT 10:05 PM!)
      expect(asr.hour, equals(15));
      // Maghrib is around 5:15 - 5:25 PM (NOT 11:47 PM!)
      expect(maghrib.hour, equals(17));
      // Isha is around 6:30 - 6:45 PM (NOT 12:54 AM!)
      expect(isha.hour, equals(18));
    });

    test('should calculate accurate Bangladesh times from AppSettings.defaults', () {
      final day = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 11, 4),
        settings: AppSettings.defaults,
      );

      final fajr = day.prayers.firstWhere((p) => p.name == 'Fajr').time;
      final dhuhr = day.prayers.firstWhere((p) => p.name == 'Dhuhr').time;
      final asr = day.prayers.firstWhere((p) => p.name == 'Asr').time;
      final maghrib = day.prayers.firstWhere((p) => p.name == 'Maghrib').time;
      final isha = day.prayers.firstWhere((p) => p.name == 'Isha').time;

      expect(day.country, equals('Bangladesh'));
      expect(day.city, equals('Dhaka'));
      expect(day.timezone, equals('Asia/Dhaka'));
      expect(fajr.hour, equals(4));
      expect(dhuhr.hour, equals(11));
      expect(asr.hour, equals(15));
      expect(maghrib.hour, equals(17));
      expect(isha.hour, equals(18));
    });

    test('should resolve Bangladesh districts accurately with distinct coordinates', () {
      final sylhet = findBdDistrict('Sylhet');
      final rajshahi = findBdDistrict('Rajshahi');
      final chittagong = findBdDistrict('Chattogram');

      expect(sylhet, isNotNull);
      expect(rajshahi, isNotNull);
      expect(chittagong, isNotNull);

      // Sylhet is east of Dhaka (higher longitude, earlier prayer times)
      expect(sylhet!.longitude, greaterThan(90.4125));
      // Rajshahi is west of Dhaka (lower longitude, later prayer times)
      expect(rajshahi!.longitude, lessThan(90.4125));

      final sylhetDay = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 11, 4),
        settings: AppSettings.defaults.copyWith(
          city: sylhet.nameEn,
          latitude: sylhet.latitude,
          longitude: sylhet.longitude,
        ),
      );

      final rajshahiDay = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 11, 4),
        settings: AppSettings.defaults.copyWith(
          city: rajshahi.nameEn,
          latitude: rajshahi.latitude,
          longitude: rajshahi.longitude,
        ),
      );

      final sylhetFajr = sylhetDay.prayers.firstWhere((p) => p.name == 'Fajr').time;
      final rajshahiFajr = rajshahiDay.prayers.firstWhere((p) => p.name == 'Fajr').time;

      // In Sylhet, Fajr is earlier than in Rajshahi by ~12-14 minutes
      expect(sylhetFajr.isBefore(rajshahiFajr), isTrue);
    });

    test('should differentiate between Hanafi and Shafi Asr calculation', () {
      final shafiDay = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 6, 21),
        settings: AppSettings.defaults.copyWith(
          madhhab: 'Shafi',
        ),
      );

      final hanafiDay = PrayerRepository.calculatePrayerDayForSettings(
        date: DateTime(2026, 6, 21),
        settings: AppSettings.defaults.copyWith(
          madhhab: 'Hanafi',
        ),
      );

      final shafiAsr = shafiDay.prayers.firstWhere((p) => p.name == 'Asr').time;
      final hanafiAsr = hanafiDay.prayers.firstWhere((p) => p.name == 'Asr').time;

      // Hanafi Asr (shadow length 2) starts significantly later than Shafi Asr (shadow length 1)
      expect(hanafiAsr.isAfter(shafiAsr), isTrue);
      expect(hanafiAsr.difference(shafiAsr).inMinutes, greaterThan(30));
    });

    test('should find geographically closest district accurately', () {
      // Coordinates near Chittagong (22.3569, 91.7832)
      final closest = findClosestBdDistrict(22.36, 91.80);
      expect(closest.nameEn, equals('Chattogram'));

      // Coordinates near Sylhet (24.8949, 91.8687)
      final sylhet = findClosestBdDistrict(24.90, 91.87);
      expect(sylhet.nameEn, equals('Sylhet'));

      // Coordinates near Khulna (22.8456, 89.5403)
      final khulna = findClosestBdDistrict(22.85, 89.53);
      expect(khulna.nameEn, equals('Khulna'));
    });
  });
}
