import 'package:islam/features/prayer/domain/prayer_time_entry.dart';

class PrayerDayData {
  const PrayerDayData({
    required this.city,
    required this.country,
    required this.timezone,
    required this.hijriLabel,
    required this.gregorianLabel,
    required this.prayers,
    required this.sunrise,
    required this.sunset,
  });

  final String city;
  final String country;
  final String timezone;
  final String hijriLabel;
  final String gregorianLabel;
  final List<PrayerTimeEntry> prayers;
  final DateTime sunrise;
  final DateTime sunset;
}
