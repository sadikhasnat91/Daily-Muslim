import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/features/dua/data/dua_repository.dart';
import 'package:islam/features/quran/data/quran_repository.dart';
import 'package:islam/features/quran/domain/surah.dart';

class UiActions {
  static void openByLabel(BuildContext context, String label) {
    final normalized = label.toLowerCase();
    if (normalized == 'home') {
      _goIfNeeded(context, AppRoutes.home);
      return;
    }
    if (normalized == 'prayer' || normalized == 'prayers') {
      _goIfNeeded(context, AppRoutes.prayerTimes);
      return;
    }
    if (normalized == 'quran') {
      _goIfNeeded(context, AppRoutes.quranBrowser);
      return;
    }
    if (normalized == 'duas') {
      _goIfNeeded(context, AppRoutes.duas);
      return;
    }
    if (normalized == 'profile') {
      _goIfNeeded(context, AppRoutes.profile);
      return;
    }
    if (normalized == 'qibla') {
      _pushIfNeeded(context, AppRoutes.qibla);
      return;
    }
    if (normalized == 'tasbih') {
      _pushIfNeeded(context, AppRoutes.tasbih);
      return;
    }
    if (normalized == 'calendar') {
      _pushIfNeeded(context, AppRoutes.calendar);
      return;
    }
  }

  static void openNotifications(BuildContext context) {
    _pushIfNeeded(context, AppRoutes.notifications);
  }

  static void openSearch(BuildContext context) {
    _pushIfNeeded(context, AppRoutes.search);
  }

  static void openSettings(BuildContext context) {
    _pushIfNeeded(context, AppRoutes.settings);
  }

  static void openPrayerTracker(BuildContext context) {
    _pushIfNeeded(context, AppRoutes.prayerTracker);
  }

  static Future<void> openContinueReading(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(quranRepositoryProvider);
    final recent = repo.getRecent();
    final recentId = (recent?['id'] as int?) ?? 1;
    openQuranReader(context, surahId: recentId);
  }

  static void openQuranReader(BuildContext context, {required int surahId}) {
    _goIfNeeded(context, AppRoutes.quranReaderPath(surahId));
  }

  static Future<void> bookmarkAyah(
    BuildContext context, {
    required String key,
    required String title,
    required String arabic,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(quranRepositoryProvider);
    await repo.bookmarkSurah(
      Surah(id: 67, name: title, arabic: arabic, verses: 30, place: 'Meccan'),
    );
    if (!context.mounted) {
      return;
    }
    _snack(context, 'Bookmarked: $title');
  }

  static Future<void> markRecentDefault(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(quranRepositoryProvider);
    await repo.markRecent(
      const Surah(
        id: 67,
        name: 'Al-Mulk',
        arabic: 'الملك',
        verses: 30,
        place: 'Meccan',
      ),
    );
  }

  static Future<void> markRecentSurah(
    BuildContext context, {
    required int id,
    required String name,
    required String arabic,
    required int verses,
    required String place,
    int ayahNumber = 1,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(quranRepositoryProvider);
    await repo.updateRecentAyah(
      surah: Surah(
        id: id,
        name: name,
        arabic: arabic,
        verses: verses,
        place: place,
      ),
      ayahNumber: ayahNumber,
    );
  }

  static Future<void> addFavoriteDua(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(duaRepositoryProvider);
    await repo.addFavorite(title, {
      'title': title,
      'subtitle': subtitle,
      'savedAt': DateTime.now().toIso8601String(),
    });
    if (!context.mounted) {
      return;
    }
    _snack(context, 'Added to favorites');
  }

  static Future<void> bookmarkSurah(
    BuildContext context, {
    required int id,
    required String name,
    required String arabic,
    required int verses,
    required String place,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = container.read(quranRepositoryProvider);
    await repo.bookmarkSurah(
      Surah(id: id, name: name, arabic: arabic, verses: verses, place: place),
    );
    if (!context.mounted) {
      return;
    }
    _snack(context, 'Bookmarked: $name');
  }

  static Future<void> shareText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    _snack(context, 'Copied for sharing');
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void _goIfNeeded(BuildContext context, String route) {
    if (_currentPath(context) == route) {
      return;
    }
    context.go(route);
  }

  static void _pushIfNeeded(BuildContext context, String route) {
    if (_currentPath(context) == route) {
      return;
    }
    context.push(route);
  }

  static String? _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return null;
    }
  }
}
