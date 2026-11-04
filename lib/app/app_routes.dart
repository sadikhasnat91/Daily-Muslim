class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const prayerTimes = '/prayer';
  static const quranBrowser = '/quran-browser';
  static const quranReader = '/quran-reader';
  static const duas = '/duas';
  static const qibla = '/qibla';
  static const calendar = '/calendar';
  static const settings = '/settings';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const tasbih = '/tasbih';
  static const prayerTracker = '/prayer-tracker';
  static const search = '/search';
  static const countrySelection = '/country-selection';

  static String quranReaderPath(int surahId) => '$quranReader/$surahId';
}
