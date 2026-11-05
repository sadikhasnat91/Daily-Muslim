import 'package:flutter/material.dart';

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.timezone,
    required this.profileName,
    required this.profileEmail,
    required this.profileImageUrl,
    required this.onboardingComplete,
    required this.prayerMethod,
    required this.madhhab,
    required this.azanEnabled,
    required this.vibrationEnabled,
    required this.silentMode,
    required this.muazzinVoice,
    required this.perPrayerNotifications,
    this.latitude = 21.4225,
    this.longitude = 39.8262,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String city;
  final String country;
  final String countryCode;
  final String timezone;
  final String profileName;
  final String profileEmail;
  final String profileImageUrl;
  final bool onboardingComplete;
  final int prayerMethod;
  final String madhhab;
  final bool azanEnabled;
  final bool vibrationEnabled;
  final bool silentMode;
  final String muazzinVoice;
  final Map<String, bool> perPrayerNotifications;
  final double latitude;
  final double longitude;

  static const defaultPerPrayerNotifications = <String, bool>{
    'Fajr': true,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  static const defaults = AppSettings(
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
    prayerMethod: 1, // Karachi (University of Islamic Sciences) - standard for Bangladesh Islamic Foundation
    madhhab: 'Hanafi', // Hanafi is standard in Bangladesh
    azanEnabled: true,
    vibrationEnabled: true,
    silentMode: false,
    muazzinVoice: 'Makkah',
    perPrayerNotifications: defaultPerPrayerNotifications,
    latitude: 23.8103,
    longitude: 90.4125,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? city,
    String? country,
    String? countryCode,
    String? timezone,
    String? profileName,
    String? profileEmail,
    String? profileImageUrl,
    bool? onboardingComplete,
    int? prayerMethod,
    String? madhhab,
    bool? azanEnabled,
    bool? vibrationEnabled,
    bool? silentMode,
    String? muazzinVoice,
    Map<String, bool>? perPrayerNotifications,
    double? latitude,
    double? longitude,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      city: city ?? this.city,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      profileName: profileName ?? this.profileName,
      profileEmail: profileEmail ?? this.profileEmail,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      madhhab: madhhab ?? this.madhhab,
      azanEnabled: azanEnabled ?? this.azanEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      silentMode: silentMode ?? this.silentMode,
      muazzinVoice: muazzinVoice ?? this.muazzinVoice,
      perPrayerNotifications:
          perPrayerNotifications ?? this.perPrayerNotifications,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'timezone': timezone,
      'profileName': profileName,
      'profileEmail': profileEmail,
      'profileImageUrl': profileImageUrl,
      'onboardingComplete': onboardingComplete,
      'prayerMethod': prayerMethod,
      'madhhab': madhhab,
      'azanEnabled': azanEnabled,
      'vibrationEnabled': vibrationEnabled,
      'silentMode': silentMode,
      'muazzinVoice': muazzinVoice,
      'perPrayerNotifications': perPrayerNotifications,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic> json) {
    final mode = ThemeMode.values.firstWhere(
      (item) => item.name == json['themeMode'],
      orElse: () => ThemeMode.dark,
    );

    return AppSettings(
      themeMode: mode,
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      city: (json['city'] as String?) ?? 'Dhaka',
      country: (json['country'] as String?) ?? 'Bangladesh',
      countryCode: (json['countryCode'] as String?) ?? 'BD',
      timezone: (json['timezone'] as String?) ?? 'Asia/Dhaka',
      profileName: (json['profileName'] as String?) ?? '',
      profileEmail: (json['profileEmail'] as String?) ?? '',
      profileImageUrl: (json['profileImageUrl'] as String?) ?? '',
      onboardingComplete: (json['onboardingComplete'] as bool?) ?? false,
      prayerMethod: (json['prayerMethod'] as int?) ?? 1,
      madhhab: (json['madhhab'] as String?) ?? 'Hanafi',
      azanEnabled: (json['azanEnabled'] as bool?) ?? true,
      vibrationEnabled: (json['vibrationEnabled'] as bool?) ?? true,
      silentMode: (json['silentMode'] as bool?) ?? false,
      muazzinVoice: (json['muazzinVoice'] as String?) ?? 'Makkah',
      perPrayerNotifications: _parsePerPrayerNotifications(
        json['perPrayerNotifications'],
      ),
      latitude: ((json['latitude'] as num?) ?? 23.8103).toDouble(),
      longitude: ((json['longitude'] as num?) ?? 90.4125).toDouble(),
    );
  }

  static Map<String, bool> _parsePerPrayerNotifications(dynamic raw) {
    if (raw is Map) {
      return {
        for (final entry in defaultPerPrayerNotifications.entries)
          entry.key: (raw[entry.key] as bool?) ?? entry.value,
      };
    }
    return defaultPerPrayerNotifications;
  }
}
