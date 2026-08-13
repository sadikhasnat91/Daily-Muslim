import 'package:timezone/timezone.dart' as tz;
import 'package:islam/core/time/app_time_service.dart';

DateTime appNowForTimezone(String timezoneId) {
  return AppTimeService.instance.nowForTimezone(timezoneId);
}

tz.Location? resolveTimezoneLocation(String timezoneId) {
  return AppTimeService.instance.locationForTimezone(timezoneId);
}

DateTime buildDateTimeForTimezone(
  String timezoneId, {
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  return AppTimeService.instance.buildDateTimeForTimezone(
    timezoneId,
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
  );
}
