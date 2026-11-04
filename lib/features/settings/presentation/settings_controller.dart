import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/settings/domain/app_settings.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final raw =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map?;
    if (raw == null) {
      return AppSettings.defaults;
    }
    var loaded = AppSettings.fromJson(raw);
    final countryLower = loaded.country.trim().toLowerCase();
    final isBangladesh = countryLower == 'bangladesh' || loaded.countryCode.toUpperCase() == 'BD';

    if ((loaded.latitude == 0.0 && loaded.longitude == 0.0) ||
        (isBangladesh && (loaded.longitude < 80.0 || loaded.latitude < 20.0))) {
      final coords = resolveCoordinates(loaded.city, loaded.country) ?? (23.8103, 90.4125);
      loaded = loaded.copyWith(
        latitude: coords.$1,
        longitude: coords.$2,
        prayerMethod: loaded.prayerMethod == 3 && isBangladesh ? 1 : loaded.prayerMethod,
        madhhab: isBangladesh && loaded.madhhab == 'Shafi' ? 'Hanafi' : loaded.madhhab,
      );
      HiveService.instance.settingsBox.put(HiveKeys.appSettings, loaded.toJson());
    }
    return loaded;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _save();
  }

  static const cityCoordinates = <String, (double, double)>{
    'dhaka': (23.8103, 90.4125),
    'chittagong': (22.3569, 91.7832),
    'chattogram': (22.3569, 91.7832),
    'sylhet': (24.8949, 91.8687),
    'rajshahi': (24.3745, 88.6042),
    'khulna': (22.8456, 89.5403),
    'barisal': (22.7010, 90.3535),
    'barishal': (22.7010, 90.3535),
    'rangpur': (25.7439, 89.2752),
    'mymensingh': (24.7471, 90.4203),
    'comilla': (23.4682, 91.1788),
    'cumilla': (23.4682, 91.1788),
    'gazipur': (23.9999, 90.4203),
    'narayanganj': (23.6238, 90.5000),
    'bogra': (24.8465, 89.3777),
    'bogura': (24.8465, 89.3777),
    'dinajpur': (25.6279, 88.6332),
    'cox\'s bazar': (21.4272, 92.0058),
    'makkah': (21.4225, 39.8262),
    'madinah': (24.5247, 39.5692),
    'riyadh': (24.7136, 46.6753),
    'jeddah': (21.5433, 39.1728),
    'kabul': (34.5553, 69.2075),
    'karachi': (24.8607, 67.0011),
    'lahore': (31.5204, 74.3587),
    'islamabad': (33.6844, 73.0479),
    'delhi': (28.6139, 77.2090),
    'new delhi': (28.6139, 77.2090),
    'mumbai': (19.0760, 72.8777),
    'kolkata': (22.5726, 88.3639),
    'london': (51.5074, -0.1278),
    'new york': (40.7128, -74.0060),
    'toronto': (43.6532, -79.3832),
    'dubai': (25.2048, 55.2708),
    'kuala lumpur': (3.1390, 101.6869),
    'jakarta': (-6.2088, 106.8456),
    'istanbul': (41.0082, 28.9784),
    'cairo': (30.0444, 31.2357),
  };

  static (double, double)? resolveCoordinates(String city, String country) {
    final normalizedCity = city.trim().toLowerCase();
    if (cityCoordinates.containsKey(normalizedCity)) {
      return cityCoordinates[normalizedCity];
    }
    final normalizedCountry = country.trim().toLowerCase();
    if (normalizedCountry == 'bangladesh') {
      return (23.8103, 90.4125);
    } else if (normalizedCountry == 'saudi arabia') {
      return (21.4225, 39.8262);
    } else if (normalizedCountry == 'india') {
      return (28.6139, 77.2090);
    } else if (normalizedCountry == 'pakistan') {
      return (33.6844, 73.0479);
    } else if (normalizedCountry == 'united kingdom' || normalizedCountry == 'uk') {
      return (51.5074, -0.1278);
    } else if (normalizedCountry == 'united states' || normalizedCountry == 'usa') {
      return (40.7128, -74.0060);
    }
    return null;
  }

  Future<void> setCity(String city) async {
    final normalized = city.trim().toLowerCase();
    final coords = cityCoordinates[normalized] ?? resolveCoordinates(city, state.country);
    if (coords != null) {
      state = state.copyWith(
        city: city.trim(),
        latitude: coords.$1,
        longitude: coords.$2,
      );
    } else {
      state = state.copyWith(city: city.trim());
    }
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setCountry(String country) async {
    final coords = resolveCoordinates(state.city, country);
    if (coords != null) {
      state = state.copyWith(
        country: country,
        latitude: coords.$1,
        longitude: coords.$2,
      );
    } else {
      state = state.copyWith(country: country);
    }
    await _save();
  }

  Future<void> applyCountry(CountryOption country) async {
    double lat = country.latitude;
    double lng = country.longitude;
    if (lat == 0.0 && lng == 0.0) {
      final coords = resolveCoordinates(country.capital, country.name);
      if (coords != null) {
        lat = coords.$1;
        lng = coords.$2;
      }
    }
    state = state.copyWith(
      country: country.name,
      countryCode: country.isoCode,
      city: country.capital,
      timezone: country.timezoneId,
      latitude: lat,
      longitude: lng,
      prayerMethod: _defaultMethodForCountry(country.isoCode),
      madhhab: _defaultMadhhabForCountry(country.isoCode),
    );
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setTimezone(String timezone) async {
    state = state.copyWith(timezone: timezone);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setProfileName(String name) async {
    state = state.copyWith(profileName: name);
    await _save();
  }

  Future<void> setProfileImageUrl(String url) async {
    state = state.copyWith(profileImageUrl: url.trim());
    await _save();
  }

  Future<void> setProfileEmail(String email) async {
    state = state.copyWith(profileEmail: email.trim());
    await _save();
  }

  Future<void> setOnboardingComplete(bool completed) async {
    state = state.copyWith(onboardingComplete: completed);
    await _save();
  }

  Future<void> setPrayerMethod(int method) async {
    state = state.copyWith(prayerMethod: method);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setMadhhab(String madhhab) async {
    state = state.copyWith(madhhab: madhhab);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setAzanEnabled(bool enabled) async {
    state = state.copyWith(azanEnabled: enabled);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setSilentMode(bool enabled) async {
    state = state.copyWith(silentMode: enabled);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setMuazzinVoice(String voice) async {
    state = state.copyWith(muazzinVoice: voice);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    final updated = {...state.perPrayerNotifications, prayer: enabled};
    state = state.copyWith(perPrayerNotifications: updated);
    await _save();
    await _rescheduleAzan();
  }

  Future<void> _save() async {
    await HiveService.instance.settingsBox.put(
      HiveKeys.appSettings,
      state.toJson(),
    );
  }

  /// Recomputes today's prayer times and re-schedules Azan notifications so
  /// they reflect the latest settings (timezone, calculation method,
  /// madhhab, per-prayer toggles, silent mode, etc.).
  Future<void> _rescheduleAzan() async {
    final repo = PrayerRepository(HiveService.instance);
    await repo.getPrayerDayData(DateTime.now());
  }

  int _defaultMethodForCountry(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    switch (code) {
      case 'BD':
      case 'PK':
      case 'IN':
      case 'AF':
        return 1; // Karachi (University of Islamic Sciences, Karachi)
      case 'SA':
      case 'AE':
      case 'QA':
      case 'KW':
      case 'BH':
      case 'OM':
      case 'YE':
        return 4; // Umm Al-Qura
      case 'EG':
      case 'SD':
      case 'LY':
      case 'DZ':
      case 'MA':
      case 'TN':
        return 5; // Egyptian General Authority of Survey
      case 'US':
      case 'CA':
        return 2; // ISNA
      case 'TR':
        return 13; // Diyanet Turkey
      case 'SG':
        return 11; // MUIS Singapore
      case 'FR':
        return 12; // UOIF France
      case 'RU':
        return 14; // Russia
      default:
        return 3; // Muslim World League (MWL) default for global
    }
  }

  String _defaultMadhhabForCountry(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    switch (code) {
      case 'BD':
      case 'PK':
      case 'IN':
      case 'AF':
      case 'TR':
        return 'Hanafi';
      default:
        return 'Shafi';
    }
  }
}
