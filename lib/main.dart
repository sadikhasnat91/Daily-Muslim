import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/app/app.dart';
import 'package:islam/core/notifications/azan_notification_service.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/time/app_time_service.dart';
import 'package:islam/features/settings/domain/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTimeService.instance.ensureInitialized();
  await HiveService.instance.init();
  await AzanNotificationService.instance.init();

  // Ensure rolling 7-day exact prayer alarms are scheduled on startup
  final rawSettings = HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map<dynamic, dynamic>?;
  final settings = rawSettings == null ? AppSettings.defaults : AppSettings.fromJson(rawSettings);
  if (settings.notificationsEnabled) {
    AzanNotificationService.instance.scheduleWeekly(settings);
  }

  runApp(const ProviderScope(child: MuslimDailyRootApp()));
}
