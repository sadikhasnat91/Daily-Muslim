import 'dart:convert';
import 'package:islam/features/prayer/data/static_prayer_data.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:islam/core/notifications/azan_notification_service.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';
import 'package:islam/features/settings/domain/app_settings.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((_) {
  return PrayerRepository(HiveService.instance);
});

class PrayerRepository {
  PrayerRepository(this._hive);

  final HiveService _hive;

  Future<List<PrayerTimeEntry>> getPrayerTimes(DateTime date) async {
    final dayData = await getPrayerDayData(date);
    return dayData.prayers;
  }

  Future<PrayerDayData> getPrayerDayData(DateTime date) async {
    final result = await _resolveDayData(date);
    _maybeScheduleNotifications(date, result);
    return result;
  }

  void _maybeScheduleNotifications(DateTime date, PrayerDayData data) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return;
    final raw =
        _hive.settingsBox.get(HiveKeys.appSettings) as Map<dynamic, dynamic>?;
    final settings = raw == null
        ? AppSettings.defaults
        : AppSettings.fromJson(raw);
    // Fire-and-forget: scheduling failures shouldn't block prayer time
    // rendering.
    AzanNotificationService.instance.scheduleForDay(data, settings);
  }

  static PrayerDayData calculatePrayerDayForSettings({
    required DateTime date,
    required AppSettings settings,
  }) {
    final coords = Coordinates(settings.latitude, settings.longitude);
    final method = _calculationMethodFrom(settings.prayerMethod);
    final params = CalculationMethodParameters.muslimWorldLeague();
    final adjusted = params.copyWith(
      method: method,
      madhab: settings.madhhab.toLowerCase() == 'hanafi'
          ? Madhab.hanafi
          : Madhab.shafi,
      highLatitudeRule: HighLatitudeRule.middleOfTheNight,
    );

    final times = PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: coords,
      calculationParameters: adjusted,
    );

    final localTimezone = settings.timezone.trim();
    final normalizedSunrise = _normalizeInstantForTimezone(
      times.sunrise,
      localTimezone,
    );
    final normalizedSunset = _normalizeInstantForTimezone(
      times.sunset,
      localTimezone,
    );

    final prayers = [
      PrayerTimeEntry(
        name: 'Fajr',
        time: _normalizeInstantForTimezone(times.fajr, localTimezone),
      ),
      PrayerTimeEntry(
        name: 'Dhuhr',
        time: _normalizeInstantForTimezone(times.dhuhr, localTimezone),
      ),
      PrayerTimeEntry(
        name: 'Asr',
        time: _normalizeInstantForTimezone(times.asr, localTimezone),
      ),
      PrayerTimeEntry(
        name: 'Maghrib',
        time: _normalizeInstantForTimezone(times.maghrib, localTimezone),
      ),
      PrayerTimeEntry(
        name: 'Isha',
        time: _normalizeInstantForTimezone(times.isha, localTimezone),
      ),
    ];

    final gregorian = DateFormat('EEEE, d MMMM, y', 'en_US').format(date);
    final hijri = _hijriLabel(date);
    return PrayerDayData(
      city: settings.city,
      country: settings.country,
      timezone: settings.timezone,
      hijriLabel: hijri,
      gregorianLabel: gregorian,
      prayers: prayers,
      sunrise: normalizedSunrise,
      sunset: normalizedSunset,
    );
  }

  static DateTime _normalizeInstantForTimezone(
    DateTime instant,
    String timezoneId,
  ) {
    final location = resolveTimezoneLocation(timezoneId);
    if (location == null) {
      return instant.toLocal();
    }
    return tz.TZDateTime.from(instant, location);
  }

  Future<PrayerDayData> _resolveDayData(DateTime date) async {
    final settings =
        _hive.settingsBox.get(HiveKeys.appSettings) as Map<dynamic, dynamic>?;
    final appSettings = settings == null
        ? AppSettings.defaults
        : AppSettings.fromJson(settings);

    final base = DateTime(date.year, date.month, date.day);
    
    PrayerDayData? calculated;
    final countryLower = appSettings.country.trim().toLowerCase();
    if (countryLower == 'bangladesh' || countryLower == 'afghanistan') {
      calculated = await _tryLoadStaticPrayerData(appSettings.country, appSettings.city, base, appSettings.timezone);
    }
    
    calculated ??= calculatePrayerDayForSettings(
      date: base,
      settings: appSettings,
    );

    await _hive.dailyProgressBox.put('prayer_day_cache', {
      'city': calculated.city,
      'country': calculated.country,
      'timezone': calculated.timezone,
      'hijriLabel': calculated.hijriLabel,
      'gregorianLabel': calculated.gregorianLabel,
      'sunrise': calculated.sunrise.toIso8601String(),
      'sunset': calculated.sunset.toIso8601String(),
      'prayers': calculated.prayers
          .map((e) => {'name': e.name, 'time': e.time.toIso8601String()})
          .toList(growable: false),
    });

    return calculated;
  }

  Future<PrayerDayData?> _tryLoadStaticPrayerData(String country, String city, DateTime date, String fallbackTimezone) async {
    try {
      final countryLower = country.trim().toLowerCase();
      Map<String, dynamic> data;
      if (countryLower == 'bangladesh') {
        data = bangladeshPrayerData;
      } else if (countryLower == 'afghanistan') {
        data = afghanistanPrayerData;
      } else {
        return null;
      }
      
      final List<dynamic> prayerTimes = data['prayer_times'];
      Map<String, dynamic>? cityData;
      for (final e in prayerTimes) {
        if ((e['city'] as String).toLowerCase() == city.trim().toLowerCase()) {
          cityData = e as Map<String, dynamic>;
          break;
        }
      }
      if (cityData == null) {
        cityData = prayerTimes.first as Map<String, dynamic>;
      }
      
      final String staticTimezone = data['timezone'] ?? fallbackTimezone;
      
      DateTime parseTime(String timeStr) {
        final format = DateFormat("hh:mm a");
        final parsedTime = format.parse(timeStr);
        return buildDateTimeForTimezone(
          staticTimezone,
          year: date.year,
          month: date.month,
          day: date.day,
          hour: parsedTime.hour,
          minute: parsedTime.minute,
        );
      }
      
      final prayers = [
        PrayerTimeEntry(name: 'Fajr', time: parseTime(cityData['fajr'])),
        PrayerTimeEntry(name: 'Dhuhr', time: parseTime(cityData['dhuhr'])),
        PrayerTimeEntry(name: 'Asr', time: parseTime(cityData['asr'])),
        PrayerTimeEntry(name: 'Maghrib', time: parseTime(cityData['maghrib'])),
        PrayerTimeEntry(name: 'Isha', time: parseTime(cityData['isha'])),
      ];
      
      final sunrise = parseTime(cityData['sunrise']);
      // using maghrib as a fallback for sunset since sunset is not explicitly in the json
      final sunset = parseTime(cityData['maghrib']);

      final gregorian = DateFormat('EEEE, d MMMM, y', 'en_US').format(date);
      final hijriLabel = data['hijri_date'] ?? _hijriLabel(date);
      
      print("Successfully parsed static data for ${cityData['city']}");
      return PrayerDayData(
        city: cityData['city'],
        country: country,
        timezone: staticTimezone,
        hijriLabel: hijriLabel,
        gregorianLabel: gregorian,
        prayers: prayers,
        sunrise: sunrise,
        sunset: sunset,
      );
    } catch (e, stack) {
      print("Error loading static prayer data: $e");
      print(stack);
      return null;
    }
  }

  static CalculationMethod _calculationMethodFrom(int methodId) {
    switch (methodId) {
      case 1:
        return CalculationMethod.karachi;
      case 2:
        return CalculationMethod.northAmerica;
      case 3:
        return CalculationMethod.muslimWorldLeague;
      case 4:
        return CalculationMethod.ummAlQura;
      case 5:
        return CalculationMethod.egyptian;
      case 11:
        return CalculationMethod.singapore;
      case 13:
        return CalculationMethod.turkiye;
      case 15:
        return CalculationMethod.moonsightingCommittee;
      case 99:
        return CalculationMethod.jafari;
      default:
        return CalculationMethod.muslimWorldLeague;
    }
  }

  static String _hijriLabel(DateTime date) {
    try {
      final hijri = HijriCalendar.fromDate(date);
      return '${hijri.getLongMonthName()} ${hijri.hDay}, ${hijri.hYear} AH';
    } catch (_) {
      return 'Hijri date';
    }
  }
}
