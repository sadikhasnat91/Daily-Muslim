import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/app/app.dart';
import 'package:islam/core/notifications/azan_notification_service.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/app_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTimeService.instance.ensureInitialized();
  await HiveService.instance.init();
  await AzanNotificationService.instance.init();
  runApp(const ProviderScope(child: MuslimDailyRootApp()));
}
