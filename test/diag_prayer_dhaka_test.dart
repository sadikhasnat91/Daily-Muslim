import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/settings/domain/app_settings.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';

void main() {
  test('Diag: calculate prayers for Dhaka 2026-08-08', () {
    final dhakaSettings = AppSettings.defaults.copyWith(
      city: 'Dhaka',
      country: 'Bangladesh',
      countryCode: 'BD',
      timezone: 'Asia/Dhaka',
      latitude: 23.8103,
      longitude: 90.4125,
    );

    final date = DateTime(2026, 8, 8);
    final day = PrayerRepository.calculatePrayerDayForSettings(
      date: date,
      settings: dhakaSettings,
    );

    print('City: ${day.city}, Timezone: ${day.timezone}');
    for (final p in day.prayers) {
      print('${p.name}: ${p.time.toIso8601String()}');
    }
    print('Sunrise: ${day.sunrise.toIso8601String()}');
    print('Sunset: ${day.sunset.toIso8601String()}');
  }, timeout: Timeout.none);
}
