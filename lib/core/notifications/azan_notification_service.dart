import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:islam/core/time/timezone_helper.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/settings/domain/app_settings.dart';

/// Professional Islamic Prayer Notification and Adhan Audio Service.
///
/// Features:
/// 1. Exact Alarm multi-day rolling schedule (7 days ahead) for all 5 daily prayers.
/// 2. Dual Android notification channels:
///    - [azanChannelId]: Plays the bundled Adhan audio (`res/raw/azan.mp3`) at maximum alarm priority.
///    - [standardChannelId]: Plays the device standard notification sound when full Adhan is toggled off.
/// 3. In-app audio player for Adhan preview and test playback via `just_audio`.
/// 4. Handles Android 13+ POST_NOTIFICATIONS and Android 12+ SCHEDULE_EXACT_ALARM permissions.
/// 5. Reschedules automatically on boot, settings changes, or location changes.
class AzanNotificationService {
  AzanNotificationService._();

  static final AzanNotificationService instance = AzanNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  bool _isPlayingAdhan = false;

  bool get isPlayingAdhan => _isPlayingAdhan;

  // Channel IDs
  static const String azanChannelId = 'azan_prayer_channel_v3';
  static const String azanChannelName = 'Azan Prayer Alarms';
  static const String azanChannelDescription =
      'Plays full Adhan audio alarm when prayer time arrives.';

  static const String standardChannelId = 'standard_prayer_channel_v3';
  static const String standardChannelName = 'Prayer Reminders';
  static const String standardChannelDescription =
      'Plays standard notification tone when prayer time arrives.';

  static const Map<String, int> _prayerBaseIndex = {
    'Fajr': 0,
    'Dhuhr': 1,
    'Asr': 2,
    'Maghrib': 3,
    'Isha': 4,
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
      onDidReceiveNotificationResponse: (details) {
        // Stop adhan audio if user taps notification
        stopAdhanAudio();
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Request Android 13+ notifications permission
      await androidPlugin?.requestNotificationsPermission();

      // Request exact alarm scheduling permission
      await androidPlugin?.requestExactAlarmsPermission();

      // 1. Channel for Full Adhan Audio
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          azanChannelId,
          azanChannelName,
          description: azanChannelDescription,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('azan'),
          enableVibration: true,
          vibrationPattern: _alarmVibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );

      // 2. Channel for Standard Notification Sound
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          standardChannelId,
          standardChannelName,
          description: standardChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _alarmVibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  /// Cancels any existing schedules and schedules all 5 prayers across the
  /// next 7 days using exact timestamps for [settings].
  Future<void> scheduleWeekly(AppSettings settings) async {
    if (kIsWeb) return;
    await init();
    await cancelAll();

    if (!settings.notificationsEnabled) {
      return;
    }

    final location = resolveTimezoneLocation(settings.timezone) ?? tz.local;
    final nowTz = tz.TZDateTime.now(location);
    final now = DateTime.now();

    const scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

    // Schedule 7 rolling days of prayers
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dayData = PrayerRepository.calculatePrayerDayForSettings(
        date: targetDate,
        settings: settings,
      );

      for (final prayer in dayData.prayers) {
        final isEnabled = settings.perPrayerNotifications[prayer.name] ?? true;
        if (!isEnabled) continue;

        final prayerIdx = _prayerBaseIndex[prayer.name] ?? 0;
        final notificationId = 1000 + (dayOffset * 10) + prayerIdx;

        final prayerTzTime = tz.TZDateTime.from(prayer.time, location);
        if (!prayerTzTime.isAfter(nowTz)) {
          // Already passed for today
          continue;
        }

        final useAzanSound = settings.azanEnabled && !settings.silentMode;
        final channelId = useAzanSound ? azanChannelId : standardChannelId;
        final channelName = useAzanSound ? azanChannelName : standardChannelName;

        final title = useAzanSound
            ? '${prayer.name} Azan 🕌'
            : '${prayer.name} Prayer Time 🕌';
        final body = "It's time for ${prayer.name} prayer in ${dayData.city}.";

        await _plugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: prayerTzTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: useAzanSound
                  ? azanChannelDescription
                  : standardChannelDescription,
              importance: Importance.max,
              priority: Priority.max,
              playSound: !settings.silentMode,
              sound: useAzanSound
                  ? const RawResourceAndroidNotificationSound('azan')
                  : null,
              enableVibration: settings.vibrationEnabled && !settings.silentMode,
              vibrationPattern: _alarmVibrationPattern,
              category: useAzanSound
                  ? AndroidNotificationCategory.alarm
                  : AndroidNotificationCategory.reminder,
              fullScreenIntent: useAzanSound,
              audioAttributesUsage: useAzanSound
                  ? AudioAttributesUsage.alarm
                  : AudioAttributesUsage.notification,
            ),
            iOS: DarwinNotificationDetails(
              presentSound: !settings.silentMode,
            ),
          ),
          androidScheduleMode: scheduleMode,
        );
      }
    }
  }

  /// Backward-compatible wrapper that schedules the full rolling week.
  Future<void> scheduleForDay(
    PrayerDayData dayData,
    AppSettings settings,
  ) async {
    await scheduleWeekly(settings);
  }

  /// Sends an immediate test notification to verify notification & sound setup.
  Future<void> sendTestNotification({
    required AppSettings settings,
    required bool testAzanAudio,
  }) async {
    if (kIsWeb) return;
    await init();

    final useAzanSound = testAzanAudio && !settings.silentMode;
    final channelId = useAzanSound ? azanChannelId : standardChannelId;
    final channelName = useAzanSound ? azanChannelName : standardChannelName;

    await _plugin.show(
      id: 9999,
      title: useAzanSound ? '🕌 Azan Sound Test' : '🕌 Prayer Reminder Test',
      body: useAzanSound
          ? 'Adhan alarm is working! You will hear this call to prayer at waqt.'
          : 'Standard prayer notification is working correctly in ${settings.city}.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: useAzanSound
              ? azanChannelDescription
              : standardChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: !settings.silentMode,
          sound: useAzanSound
              ? const RawResourceAndroidNotificationSound('azan')
              : null,
          enableVibration: settings.vibrationEnabled && !settings.silentMode,
          vibrationPattern: _alarmVibrationPattern,
          category: useAzanSound
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.reminder,
          audioAttributesUsage: useAzanSound
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: !settings.silentMode,
        ),
      ),
    );
  }

  /// Plays the full Adhan audio in-app using just_audio.
  Future<void> playAdhanAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset('assets/audio/azan.mp3');
      _isPlayingAdhan = true;
      await _audioPlayer.play();
    } catch (_) {
      _isPlayingAdhan = false;
    }
  }

  /// Stops in-app Adhan playback.
  Future<void> stopAdhanAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _isPlayingAdhan = false;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}

