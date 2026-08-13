import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  final coords = Coordinates(21.4225, 39.8262);
  final date = DateTime(2026, 8, 8);
  final params = CalculationMethodParameters.ummAlQura().copyWith(
    madhab: Madhab.shafi,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
  );
  final times = PrayerTimes(date: date, coordinates: coords, calculationParameters: params);
  print('raw fajr: ${times.fajr}');
  print('raw dhuhr: ${times.dhuhr}');
  print('raw asr: ${times.asr}');
  print('raw maghrib: ${times.maghrib}');
  print('raw isha: ${times.isha}');
  final kuala = tz.getLocation('Asia/Riyadh');
  print('dhuhr in Asia/Riyadh: ${tz.TZDateTime.from(times.dhuhr, kuala)}');
  print('now local: ${DateTime.now()}');
}
