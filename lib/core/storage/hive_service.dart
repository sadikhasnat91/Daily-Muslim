import 'package:hive_flutter/hive_flutter.dart';
import 'package:islam/core/storage/hive_keys.dart';

class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  late final Box<dynamic> settingsBox;
  late final Box<dynamic> bookmarksBox;
  late final Box<dynamic> prayerTrackerBox;
  late final Box<dynamic> tasbihBox;
  late final Box<dynamic> recentlyReadBox;
  late final Box<dynamic> favoritesBox;
  late final Box<dynamic> dailyProgressBox;

  Future<void> init() async {
    await Hive.initFlutter();
    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    bookmarksBox = await Hive.openBox<dynamic>(HiveBoxes.bookmarks);
    prayerTrackerBox = await Hive.openBox<dynamic>(HiveBoxes.prayerTracker);
    tasbihBox = await Hive.openBox<dynamic>(HiveBoxes.tasbih);
    recentlyReadBox = await Hive.openBox<dynamic>(HiveBoxes.recentlyRead);
    favoritesBox = await Hive.openBox<dynamic>(HiveBoxes.favorites);
    dailyProgressBox = await Hive.openBox<dynamic>(HiveBoxes.dailyProgress);

    if (settingsBox.get(HiveKeys.installDate) == null) {
      await settingsBox.put(
        HiveKeys.installDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// The date the app was first launched on this device, used to avoid
  /// counting prayers as "missed" for days before the app was installed.
  DateTime get installDate {
    final raw = settingsBox.get(HiveKeys.installDate) as String?;
    return DateTime.tryParse(raw ?? '') ?? DateTime.now();
  }
}
