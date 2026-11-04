import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/features/prayer/data/prayer_repository.dart';
import 'package:islam/features/prayer/domain/prayer_day_data.dart';
import 'package:islam/features/prayer/domain/prayer_time_entry.dart';

final prayerTimesProvider = FutureProvider<List<PrayerTimeEntry>>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getPrayerTimes(DateTime.now());
});

/// Full prayer-day bundle (Hijri/Gregorian labels, sunrise/sunset, prayer
/// list) for today, resolved using the currently selected country/timezone.
final prayerDayDataProvider = FutureProvider<PrayerDayData>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getPrayerDayData(DateTime.now());
});

const kTrackedPrayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _trackerKey(DateTime date, String prayer) => '${_dateKey(date)}_$prayer';

final prayerTrackerProvider =
    NotifierProvider<PrayerTrackerController, Map<String, bool>>(
  PrayerTrackerController.new,
);

/// Tracks whether each of today's five daily prayers has been marked as
/// completed. Entries are persisted per-date (`YYYY-MM-DD_PrayerName`) so
/// historical completion can be used for monthly counts and streaks.
class PrayerTrackerController extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return _readDay(DateTime.now());
  }

  Map<String, bool> _readDay(DateTime date) {
    final box = HiveService.instance.prayerTrackerBox;
    return {
      for (final name in kTrackedPrayerNames)
        name: (box.get(_trackerKey(date, name)) as bool?) ?? false,
    };
  }

  Future<void> toggle(String prayer) async {
    final current = state[prayer] ?? false;
    await HiveService.instance.prayerTrackerBox
        .put(_trackerKey(DateTime.now(), prayer), !current);
    final updated = {...state, prayer: !current};
    state = updated;
  }

  Future<void> setCompleted(String prayer, bool completed) async {
    if (state[prayer] == completed) return;
    await HiveService.instance.prayerTrackerBox
        .put(_trackerKey(DateTime.now(), prayer), completed);
    final updated = {...state, prayer: completed};
    state = updated;
  }
}

/// Number of individual prayers marked completed so far in [date]'s month.
int monthlyCompletedPrayerCount(DateTime date) {
  final box = HiveService.instance.prayerTrackerBox;
  final installDate = HiveService.instance.installDate;
  var count = 0;
  final lastDay = DateTime(date.year, date.month + 1, 0).day;
  for (var day = 1; day <= lastDay; day++) {
    final current = DateTime(date.year, date.month, day);
    if (current.isAfter(date)) break;
    if (current.isBefore(
      DateTime(installDate.year, installDate.month, installDate.day),
    )) {
      continue;
    }
    for (final name in kTrackedPrayerNames) {
      if ((box.get(_trackerKey(current, name)) as bool?) ?? false) {
        count++;
      }
    }
  }
  return count;
}

/// Consecutive number of days (ending today) where all five daily prayers
/// were marked completed.
int currentPrayerStreakDays(DateTime today) {
  final box = HiveService.instance.prayerTrackerBox;
  final installDate = HiveService.instance.installDate;
  var streak = 0;
  var cursor = DateTime(today.year, today.month, today.day);
  final earliest = DateTime(installDate.year, installDate.month, installDate.day);
  while (!cursor.isBefore(earliest)) {
    final allDone = kTrackedPrayerNames.every(
      (name) => (box.get(_trackerKey(cursor, name)) as bool?) ?? false,
    );
    if (!allDone) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Count of prayers on days strictly before today (but on/after the app's
/// install date) that were never marked completed (i.e. missed / owed as
/// Qada).
int missedPrayerCount(DateTime today, {int lookBackDays = 30}) {
  final box = HiveService.instance.prayerTrackerBox;
  final installDate = HiveService.instance.installDate;
  final earliest = DateTime(installDate.year, installDate.month, installDate.day);
  var missed = 0;
  for (var offset = 1; offset < lookBackDays; offset++) {
    final day = DateTime(today.year, today.month, today.day - offset);
    if (day.isBefore(earliest)) break;
    for (final name in kTrackedPrayerNames) {
      final done = (box.get(_trackerKey(day, name)) as bool?) ?? false;
      if (!done) {
        missed++;
      }
    }
  }
  return missed;
}

String nextPrayerCountdown(List<PrayerTimeEntry> entries, DateTime now) {
  for (final entry in entries) {
    if (entry.time.isAfter(now)) {
      final diff = entry.time.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return '${entry.name} in ${hours}h ${minutes}m';
    }
  }
  final firstTomorrow = entries.first.time.add(const Duration(days: 1));
  final diff = firstTomorrow.difference(now);
  final hours = diff.inHours;
  final minutes = diff.inMinutes.remainder(60);
  return '${entries.first.name} in ${hours}h ${minutes}m';
}
