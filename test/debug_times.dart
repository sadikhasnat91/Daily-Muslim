import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  tz.initializeTimeZones();
  
  // 1. Fetch Dhaka prayer times
  final dio = Dio();
  try {
    final response = await dio.get('https://api.aladhan.com/v1/timingsByCity', queryParameters: {
      'city': 'Dhaka',
      'country': 'Bangladesh',
      'method': 4, // Umm Al-Qura
    });
    print('API TIMINGS FOR DHAKA:');
    print(jsonEncode(response.data['data']['timings']));
  } catch (e) {
    print('Failed to fetch from API: $e');
  }

  // 2. Local vs Dhaka times
  final dhakaLoc = tz.getLocation('Asia/Dhaka');
  final riyadhLoc = tz.getLocation('Asia/Riyadh');
  final nowLocal = DateTime.now();
  final nowDhaka = tz.TZDateTime.now(dhakaLoc);
  final nowRiyadh = tz.TZDateTime.now(riyadhLoc);

  print('Current Local DateTime: $nowLocal');
  print('Current Dhaka TZDateTime: $nowDhaka');
  print('Current Riyadh TZDateTime: $nowRiyadh');
}
