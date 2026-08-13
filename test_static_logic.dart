import 'package:intl/intl.dart';
import 'package:islam/features/prayer/data/static_prayer_data.dart';
import 'package:islam/core/time/app_time_service.dart';

void main() async {
  AppTimeService.instance.ensureInitialized();
  
  try {
    final date = DateTime.now();
    final country = 'Bangladesh';
    final city = 'Dhaka';
    final fallbackTimezone = 'Asia/Dhaka';

    final countryLower = country.trim().toLowerCase();
    Map<String, dynamic> data;
    if (countryLower == 'bangladesh') {
      data = bangladeshPrayerData;
    } else if (countryLower == 'afghanistan') {
      data = afghanistanPrayerData;
    } else {
      throw Exception("Country not found");
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
      return AppTimeService.instance.buildDateTimeForTimezone(
        staticTimezone,
        year: date.year,
        month: date.month,
        day: date.day,
        hour: parsedTime.hour,
        minute: parsedTime.minute,
      );
    }
    
    final dhuhr = parseTime(cityData['dhuhr']);
    print("Success!");
    print("Dhuhr: $dhuhr");
  } catch (e, stack) {
    print("Error occurred: $e");
    print(stack);
  }
}
