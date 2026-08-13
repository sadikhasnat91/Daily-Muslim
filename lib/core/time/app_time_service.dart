import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AppTimeService {
  AppTimeService._();

  static final AppTimeService instance = AppTimeService._();

  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  tz.Location? locationForTimezone(String timezoneId) {
    ensureInitialized();

    final normalized = timezoneId.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'local') {
      return null;
    }

    try {
      return tz.getLocation(normalized);
    } on Object {
      return null;
    }
  }

  DateTime nowForTimezone(String timezoneId) {
    final location = locationForTimezone(timezoneId);
    if (location == null) {
      return DateTime.now();
    }
    return tz.TZDateTime.now(location);
  }

  DateTime buildDateTimeForTimezone(
    String timezoneId, {
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    final location = locationForTimezone(timezoneId);
    if (location == null) {
      return DateTime(year, month, day, hour, minute);
    }
    return tz.TZDateTime(location, year, month, day, hour, minute);
  }
}
