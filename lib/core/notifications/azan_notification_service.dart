import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/settings/domain/app_settings.dart';

/// Schedules and manages local "Azan" notifications for the five daily
/// prayers. Notifications are scheduled with the OS alarm manager so they
/// still fire even if the app has been closed/killed.
///
/// Muazzin voice / custom Azan audio: Android notification sounds must be
/// bundled as local raw resources (a network URL cannot be used as a
/// notification sound). Until real Azan audio assets are added under
/// `android/app/src/main/res/raw/`, notifications use the platform default
/// sound; add files named to match [AppSettings.muazzinVoice] (lower-cased,
/// spaces replaced with `_`) as `raw/azan_<voice>.mp3` and update
/// [_soundForVoice] to wire them in.
class AzanNotificationService {
  AzanNotificationService._();

  static final AzanNotificationService instance = AzanNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'azan_alarm_channel_v2';
  static const _channelName = 'Azan Prayer Alarm';
  static const _channelDescription =
      'Plays Azan alarm audio and sends reminders when prayer time arrives.';

  /// Fixed notification IDs so re-scheduling a prayer replaces its previous
  /// alarm instead of stacking duplicates.
  static const Map<String, int> _prayerNotificationIds = {
    'Fajr': 101,
    'Dhuhr': 102,
    'Asr': 103,
    'Maghrib': 104,
    'Isha': 105,
  };

  static final _alarmVibrationPattern =
      Int64List.fromList([0, 1000, 500, 1000, 500, 2000]);

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('azan'),
        enableVibration: true,
        vibrationPattern: _alarmVibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Cancels any previously scheduled prayer notifications and schedules
  /// fresh ones for [dayData] according to [settings]. Safe to call every
  /// time prayer times are (re)loaded — e.g. app start, daily refresh, or
  /// whenever the user changes country/timezone/azan settings.
  Future<void> scheduleForDay(
    PrayerDayData dayData,
    AppSettings settings,
  ) async {
    if (kIsWeb) return;
    await init();
    await cancelAll();

    if (!settings.azanEnabled) {
      return;
    }

    final location = resolveTimezoneLocation(dayData.timezone) ??
        resolveTimezoneLocation(settings.timezone);
    final now = DateTime.now();

    for (final prayer in dayData.prayers) {
      final enabled = settings.perPrayerNotifications[prayer.name] ?? true;
      if (!enabled) continue;

      final id = _prayerNotificationIds[prayer.name];
      if (id == null) continue;

      var scheduledTime = prayer.time;
      if (scheduledTime.isBefore(now)) {
        // If the prayer time has already passed today, schedule it for tomorrow
        // so the alarm rings tomorrow morning without requiring an app relaunch.
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final tzTime = location != null
          ? tz.TZDateTime.from(scheduledTime, location)
          : tz.TZDateTime.from(scheduledTime, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: '${prayer.name} Azan 🕌',
        body: "It's time for ${prayer.name} prayer in ${dayData.city}.",
        scheduledDate: tzTime,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            playSound: !settings.silentMode,
            sound: _soundForVoice(settings.muazzinVoice),
            enableVibration: settings.vibrationEnabled && !settings.silentMode,
            vibrationPattern: _alarmVibrationPattern,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: !settings.silentMode,
            sound: settings.silentMode
                ? null
                : _iosSoundForVoice(settings.muazzinVoice),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Android notification sound resource lookup for a given muazzin voice.
  /// Returns null (platform default sound) until matching files are added
  /// under `android/app/src/main/res/raw/`.
  AndroidNotificationSound? _soundForVoice(String voice) {
    if (kIsWeb || !Platform.isAndroid) return null;
    return const RawResourceAndroidNotificationSound('azan');
  }

  String? _iosSoundForVoice(String voice) {
    // Expected bundled filename once assets are supplied, e.g.
    // 'azan_makkah.caf'. Returns null (default sound) until then.
    return null;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (final id in _prayerNotificationIds.values) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelPrayer(String name) async {
    if (kIsWeb) return;
    final id = _prayerNotificationIds[name];
    if (id != null) {
      await _plugin.cancel(id: id);
    }
  }
}
