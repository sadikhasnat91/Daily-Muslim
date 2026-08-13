import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  tz.initializeTimeZones();
  final location = tz.getLocation('Asia/Riyadh');
  final utc = DateTime.utc(2026, 8, 8, 9, 26);
  final local = TZDateTime.from(utc, location);
  print('utc: $utc');
  print('local: $local');
  print('format utc: ${DateFormat('h:mm a').format(utc)}');
  print('format local: ${DateFormat('h:mm a').format(local)}');
  print('format local as local: ${DateFormat('h:mm a').format(local.toLocal())}');
}
