import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:islam/features/settings/presentation/settings_controller.dart';

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
    double lat = settings.latitude;
    double lng = settings.longitude;
    final countryLower = settings.country.trim().toLowerCase();
    final isBangladesh = countryLower == 'bangladesh' ||
        countryLower.isEmpty ||
        settings.countryCode.toUpperCase() == 'BD';

    if ((lat == 0.0 && lng == 0.0) || (isBangladesh && (lng < 80.0 || lat < 20.0))) {
      final resolved = SettingsController.resolveCoordinates(settings.city, settings.country) ?? (23.8103, 90.4125);
      lat = resolved.$1;
      lng = resolved.$2;
    }

    final coords = Coordinates(lat, lng);
    final methodId = isBangladesh ? 1 : settings.prayerMethod;
    final params = _calculationParametersFor(methodId);
    final isHanafi = isBangladesh ? true : (settings.madhhab.toLowerCase() == 'hanafi');
    final adjusted = params.copyWith(
      madhab: isHanafi ? Madhab.hanafi : Madhab.shafi,
      highLatitudeRule: HighLatitudeRule.middleOfTheNight,
    );

    final times = PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: coords,
      calculationParameters: adjusted,
    );

    final localTimezone = (isBangladesh && (settings.timezone.isEmpty || settings.timezone == 'Asia/Riyadh'))
        ? 'Asia/Dhaka'
        : (settings.timezone.trim().isEmpty ? 'Asia/Dhaka' : settings.timezone.trim());

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
      city: isBangladesh && settings.city.trim().isEmpty ? 'Dhaka' : settings.city,
      country: isBangladesh && settings.country.trim().isEmpty ? 'Bangladesh' : settings.country,
      timezone: localTimezone,
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

    PrayerDayData calculated;
    try {
      calculated = calculatePrayerDayForSettings(
        date: base,
        settings: appSettings,
      );
    } catch (_) {
      calculated = calculatePrayerDayForSettings(
        date: base,
        settings: AppSettings.defaults,
      );
    }

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

  static CalculationParameters _calculationParametersFor(int methodId) {
    switch (methodId) {
      case 1:
        return CalculationMethodParameters.karachi();
      case 2:
        return CalculationMethodParameters.northAmerica();
      case 3:
        return CalculationMethodParameters.muslimWorldLeague();
      case 4:
        return CalculationMethodParameters.ummAlQura();
      case 5:
        return CalculationMethodParameters.egyptian();
      case 11:
        return CalculationMethodParameters.singapore();
      case 13:
        return CalculationMethodParameters.turkiye();
      case 15:
        return CalculationMethodParameters.moonsightingCommittee();
      case 99:
        return CalculationMethodParameters.jafari();
      default:
        return CalculationMethodParameters.karachi();
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
