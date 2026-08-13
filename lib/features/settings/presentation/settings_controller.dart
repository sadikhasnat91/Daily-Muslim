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
    return AppSettings.fromJson(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _save();
  }

  Future<void> setCity(String city) async {
    state = state.copyWith(city: city);
    await _save();
  }

  Future<void> setCountry(String country) async {
    state = state.copyWith(country: country);
    await _save();
  }

  Future<void> applyCountry(CountryOption country) async {
    state = state.copyWith(
      country: country.name,
      countryCode: country.isoCode,
      city: country.capital,
      timezone: country.timezoneId,
      latitude: country.latitude,
      longitude: country.longitude,
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
