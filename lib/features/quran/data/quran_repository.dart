import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/network/api_client.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/features/quran/domain/quran_surah_detail.dart';
import 'package:islam/features/quran/domain/surah.dart';

final quranRepositoryProvider = Provider<QuranRepository>((_) {
  return QuranRepository(HiveService.instance);
});

class QuranRepository {
  QuranRepository(this._hive);

  final HiveService _hive;

  static const allSurahs = [
    Surah(
      id: 1,
      name: 'Al-Fatihah',
      arabic: 'الفاتحة',
      verses: 7,
      place: 'Meccan',
    ),
    Surah(
      id: 2,
      name: 'Al-Baqarah',
      arabic: 'البقرة',
      verses: 286,
      place: 'Medinan',
    ),
    Surah(
      id: 3,
      name: 'Aal-E-Imran',
      arabic: 'آل عمران',
      verses: 200,
      place: 'Medinan',
    ),
    Surah(
      id: 4,
      name: 'An-Nisa',
      arabic: 'النساء',
      verses: 176,
      place: 'Medinan',
    ),
    Surah(
      id: 5,
      name: 'Al-Maidah',
      arabic: 'المائدة',
      verses: 120,
      place: 'Medinan',
    ),
    Surah(
      id: 6,
      name: 'Al-Anam',
      arabic: 'الأنعام',
      verses: 165,
      place: 'Meccan',
    ),
    Surah(
      id: 7,
      name: 'Al-Araf',
      arabic: 'الأعراف',
      verses: 206,
      place: 'Meccan',
    ),
    Surah(
      id: 8,
      name: 'Al-Anfal',
      arabic: 'الأنفال',
      verses: 75,
      place: 'Medinan',
    ),
    Surah(
      id: 9,
      name: 'At-Tawbah',
      arabic: 'التوبة',
      verses: 129,
      place: 'Medinan',
    ),
    Surah(id: 10, name: 'Yunus', arabic: 'يونس', verses: 109, place: 'Meccan'),
    Surah(id: 11, name: 'Hud', arabic: 'هود', verses: 123, place: 'Meccan'),
    Surah(id: 12, name: 'Yusuf', arabic: 'يوسف', verses: 111, place: 'Meccan'),
    Surah(
      id: 13,
      name: 'Ar-Rad',
      arabic: 'الرعد',
      verses: 43,
      place: 'Medinan',
    ),
    Surah(
      id: 14,
      name: 'Ibrahim',
      arabic: 'إبراهيم',
      verses: 52,
      place: 'Meccan',
    ),
    Surah(
      id: 15,
      name: 'Al-Hijr',
      arabic: 'الحجر',
      verses: 99,
      place: 'Meccan',
    ),
    Surah(
      id: 16,
      name: 'An-Nahl',
      arabic: 'النحل',
      verses: 128,
      place: 'Meccan',
    ),
    Surah(
      id: 17,
      name: 'Al-Isra',
      arabic: 'الإسراء',
      verses: 111,
      place: 'Meccan',
    ),
    Surah(
      id: 18,
      name: 'Al-Kahf',
      arabic: 'الكهف',
      verses: 110,
      place: 'Meccan',
    ),
    Surah(id: 19, name: 'Maryam', arabic: 'مريم', verses: 98, place: 'Meccan'),
    Surah(id: 20, name: 'Ta-Ha', arabic: 'طه', verses: 135, place: 'Meccan'),
    Surah(
      id: 21,
      name: 'Al-Anbiya',
      arabic: 'الأنبياء',
      verses: 112,
      place: 'Meccan',
    ),
    Surah(
      id: 22,
      name: 'Al-Hajj',
      arabic: 'الحج',
      verses: 78,
      place: 'Medinan',
    ),
    Surah(
      id: 23,
      name: 'Al-Muminun',
      arabic: 'المؤمنون',
      verses: 118,
      place: 'Meccan',
    ),
    Surah(
      id: 24,
      name: 'An-Nur',
      arabic: 'النور',
      verses: 64,
      place: 'Medinan',
    ),
    Surah(
      id: 25,
      name: 'Al-Furqan',
      arabic: 'الفرقان',
      verses: 77,
      place: 'Meccan',
    ),
    Surah(
      id: 26,
      name: 'Ash-Shuara',
      arabic: 'الشعراء',
      verses: 227,
      place: 'Meccan',
    ),
    Surah(
      id: 27,
      name: 'An-Naml',
      arabic: 'النمل',
      verses: 93,
      place: 'Meccan',
    ),
    Surah(
      id: 28,
      name: 'Al-Qasas',
      arabic: 'القصص',
      verses: 88,
      place: 'Meccan',
    ),
    Surah(
      id: 29,
      name: 'Al-Ankabut',
      arabic: 'العنكبوت',
      verses: 69,
      place: 'Meccan',
    ),
    Surah(id: 30, name: 'Ar-Rum', arabic: 'الروم', verses: 60, place: 'Meccan'),
    Surah(id: 31, name: 'Luqman', arabic: 'لقمان', verses: 34, place: 'Meccan'),
    Surah(
      id: 32,
      name: 'As-Sajdah',
      arabic: 'السجدة',
      verses: 30,
      place: 'Meccan',
    ),
    Surah(
      id: 33,
      name: 'Al-Ahzab',
      arabic: 'الأحزاب',
      verses: 73,
      place: 'Medinan',
    ),
    Surah(id: 34, name: 'Saba', arabic: 'سبإ', verses: 54, place: 'Meccan'),
    Surah(id: 35, name: 'Fatir', arabic: 'فاطر', verses: 45, place: 'Meccan'),
    Surah(id: 36, name: 'Ya-Sin', arabic: 'يس', verses: 83, place: 'Meccan'),
    Surah(
      id: 37,
      name: 'As-Saffat',
      arabic: 'الصافات',
      verses: 182,
      place: 'Meccan',
    ),
    Surah(id: 38, name: 'Sad', arabic: 'ص', verses: 88, place: 'Meccan'),
    Surah(
      id: 39,
      name: 'Az-Zumar',
      arabic: 'الزمر',
      verses: 75,
      place: 'Meccan',
    ),
    Surah(id: 40, name: 'Ghafir', arabic: 'غافر', verses: 85, place: 'Meccan'),
    Surah(
      id: 41,
      name: 'Fussilat',
      arabic: 'فصلت',
      verses: 54,
      place: 'Meccan',
    ),
    Surah(
      id: 42,
      name: 'Ash-Shura',
      arabic: 'الشورى',
      verses: 53,
      place: 'Meccan',
    ),
    Surah(
      id: 43,
      name: 'Az-Zukhruf',
      arabic: 'الزخرف',
      verses: 89,
      place: 'Meccan',
    ),
    Surah(
      id: 44,
      name: 'Ad-Dukhan',
      arabic: 'الدخان',
      verses: 59,
      place: 'Meccan',
    ),
    Surah(
      id: 45,
      name: 'Al-Jathiyah',
      arabic: 'الجاثية',
      verses: 37,
      place: 'Meccan',
    ),
    Surah(
      id: 46,
      name: 'Al-Ahqaf',
      arabic: 'الأحقاف',
      verses: 35,
      place: 'Meccan',
    ),
    Surah(
      id: 47,
      name: 'Muhammad',
      arabic: 'محمد',
      verses: 38,
      place: 'Medinan',
    ),
    Surah(
      id: 48,
      name: 'Al-Fath',
      arabic: 'الفتح',
      verses: 29,
      place: 'Medinan',
    ),
    Surah(
      id: 49,
      name: 'Al-Hujurat',
      arabic: 'الحجرات',
      verses: 18,
      place: 'Medinan',
    ),
    Surah(id: 50, name: 'Qaf', arabic: 'ق', verses: 45, place: 'Meccan'),
    Surah(
      id: 51,
      name: 'Adh-Dhariyat',
      arabic: 'الذاريات',
      verses: 60,
      place: 'Meccan',
    ),
    Surah(id: 52, name: 'At-Tur', arabic: 'الطور', verses: 49, place: 'Meccan'),
    Surah(
      id: 53,
      name: 'An-Najm',
      arabic: 'النجم',
      verses: 62,
      place: 'Meccan',
    ),
    Surah(
      id: 54,
      name: 'Al-Qamar',
      arabic: 'القمر',
      verses: 55,
      place: 'Meccan',
    ),
    Surah(
      id: 55,
      name: 'Ar-Rahman',
      arabic: 'الرحمن',
      verses: 78,
      place: 'Medinan',
    ),
    Surah(
      id: 56,
      name: 'Al-Waqiah',
      arabic: 'الواقعة',
      verses: 96,
      place: 'Meccan',
    ),
    Surah(
      id: 57,
      name: 'Al-Hadid',
      arabic: 'الحديد',
      verses: 29,
      place: 'Medinan',
    ),
    Surah(
      id: 58,
      name: 'Al-Mujadila',
      arabic: 'المجادلة',
      verses: 22,
      place: 'Medinan',
    ),
    Surah(
      id: 59,
      name: 'Al-Hashr',
      arabic: 'الحشر',
      verses: 24,
      place: 'Medinan',
    ),
    Surah(
      id: 60,
      name: 'Al-Mumtahanah',
      arabic: 'الممتحنة',
      verses: 13,
      place: 'Medinan',
    ),
    Surah(
      id: 61,
      name: 'As-Saff',
      arabic: 'الصف',
      verses: 14,
      place: 'Medinan',
    ),
    Surah(
      id: 62,
      name: 'Al-Jumuah',
      arabic: 'الجمعة',
      verses: 11,
      place: 'Medinan',
    ),
    Surah(
      id: 63,
      name: 'Al-Munafiqun',
      arabic: 'المنافقون',
      verses: 11,
      place: 'Medinan',
    ),
    Surah(
      id: 64,
      name: 'At-Taghabun',
      arabic: 'التغابن',
      verses: 18,
      place: 'Medinan',
    ),
    Surah(
      id: 65,
      name: 'At-Talaq',
      arabic: 'الطلاق',
      verses: 12,
      place: 'Medinan',
    ),
    Surah(
      id: 66,
      name: 'At-Tahrim',
      arabic: 'التحريم',
      verses: 12,
      place: 'Medinan',
    ),
    Surah(
      id: 67,
      name: 'Al-Mulk',
      arabic: 'الملك',
      verses: 30,
      place: 'Meccan',
    ),
    Surah(
      id: 68,
      name: 'Al-Qalam',
      arabic: 'القلم',
      verses: 52,
      place: 'Meccan',
    ),
    Surah(
      id: 69,
      name: 'Al-Haqqah',
      arabic: 'الحاقة',
      verses: 52,
      place: 'Meccan',
    ),
    Surah(
      id: 70,
      name: 'Al-Maarij',
      arabic: 'المعارج',
      verses: 44,
      place: 'Meccan',
    ),
    Surah(id: 71, name: 'Nuh', arabic: 'نوح', verses: 28, place: 'Meccan'),
    Surah(id: 72, name: 'Al-Jinn', arabic: 'الجن', verses: 28, place: 'Meccan'),
    Surah(
      id: 73,
      name: 'Al-Muzzammil',
      arabic: 'المزمل',
      verses: 20,
      place: 'Meccan',
    ),
    Surah(
      id: 74,
      name: 'Al-Muddaththir',
      arabic: 'المدثر',
      verses: 56,
      place: 'Meccan',
    ),
    Surah(
      id: 75,
      name: 'Al-Qiyamah',
      arabic: 'القيامة',
      verses: 40,
      place: 'Meccan',
    ),
    Surah(
      id: 76,
      name: 'Al-Insan',
      arabic: 'الإنسان',
      verses: 31,
      place: 'Medinan',
    ),
    Surah(
      id: 77,
      name: 'Al-Mursalat',
      arabic: 'المرسلات',
      verses: 50,
      place: 'Meccan',
    ),
    Surah(
      id: 78,
      name: 'An-Naba',
      arabic: 'النبأ',
      verses: 40,
      place: 'Meccan',
    ),
    Surah(
      id: 79,
      name: 'An-Naziat',
      arabic: 'النازعات',
      verses: 46,
      place: 'Meccan',
    ),
    Surah(id: 80, name: 'Abasa', arabic: 'عبس', verses: 42, place: 'Meccan'),
    Surah(
      id: 81,
      name: 'At-Takwir',
      arabic: 'التكوير',
      verses: 29,
      place: 'Meccan',
    ),
    Surah(
      id: 82,
      name: 'Al-Infitar',
      arabic: 'الإنفطار',
      verses: 19,
      place: 'Meccan',
    ),
    Surah(
      id: 83,
      name: 'Al-Mutaffifin',
      arabic: 'المطففين',
      verses: 36,
      place: 'Meccan',
    ),
    Surah(
      id: 84,
      name: 'Al-Inshiqaq',
      arabic: 'الإنشقاق',
      verses: 25,
      place: 'Meccan',
    ),
    Surah(
      id: 85,
      name: 'Al-Buruj',
      arabic: 'البروج',
      verses: 22,
      place: 'Meccan',
    ),
    Surah(
      id: 86,
      name: 'At-Tariq',
      arabic: 'الطارق',
      verses: 17,
      place: 'Meccan',
    ),
    Surah(
      id: 87,
      name: 'Al-Ala',
      arabic: 'الأعلى',
      verses: 19,
      place: 'Meccan',
    ),
    Surah(
      id: 88,
      name: 'Al-Ghashiyah',
      arabic: 'الغاشية',
      verses: 26,
      place: 'Meccan',
    ),
    Surah(
      id: 89,
      name: 'Al-Fajr',
      arabic: 'الفجر',
      verses: 30,
      place: 'Meccan',
    ),
    Surah(
      id: 90,
      name: 'Al-Balad',
      arabic: 'البلد',
      verses: 20,
      place: 'Meccan',
    ),
    Surah(
      id: 91,
      name: 'Ash-Shams',
      arabic: 'الشمس',
      verses: 15,
      place: 'Meccan',
    ),
    Surah(
      id: 92,
      name: 'Al-Layl',
      arabic: 'الليل',
      verses: 21,
      place: 'Meccan',
    ),
    Surah(
      id: 93,
      name: 'Ad-Duhaa',
      arabic: 'الضحى',
      verses: 11,
      place: 'Meccan',
    ),
    Surah(
      id: 94,
      name: 'Ash-Sharh',
      arabic: 'الشرح',
      verses: 8,
      place: 'Meccan',
    ),
    Surah(id: 95, name: 'At-Tin', arabic: 'التين', verses: 8, place: 'Meccan'),
    Surah(
      id: 96,
      name: 'Al-Alaq',
      arabic: 'العلق',
      verses: 19,
      place: 'Meccan',
    ),
    Surah(id: 97, name: 'Al-Qadr', arabic: 'القدر', verses: 5, place: 'Meccan'),
    Surah(
      id: 98,
      name: 'Al-Bayyinah',
      arabic: 'البينة',
      verses: 8,
      place: 'Medinan',
    ),
    Surah(
      id: 99,
      name: 'Az-Zalzalah',
      arabic: 'الزلزلة',
      verses: 8,
      place: 'Medinan',
    ),
    Surah(
      id: 100,
      name: 'Al-Adiyat',
      arabic: 'العاديات',
      verses: 11,
      place: 'Meccan',
    ),
    Surah(
      id: 101,
      name: 'Al-Qariah',
      arabic: 'القارعة',
      verses: 11,
      place: 'Meccan',
    ),
    Surah(
      id: 102,
      name: 'At-Takathur',
      arabic: 'التكاثر',
      verses: 8,
      place: 'Meccan',
    ),
    Surah(id: 103, name: 'Al-Asr', arabic: 'العصر', verses: 3, place: 'Meccan'),
    Surah(
      id: 104,
      name: 'Al-Humazah',
      arabic: 'الهمزة',
      verses: 9,
      place: 'Meccan',
    ),
    Surah(id: 105, name: 'Al-Fil', arabic: 'الفيل', verses: 5, place: 'Meccan'),
    Surah(id: 106, name: 'Quraysh', arabic: 'قريش', verses: 4, place: 'Meccan'),
    Surah(
      id: 107,
      name: 'Al-Maun',
      arabic: 'الماعون',
      verses: 7,
      place: 'Meccan',
    ),
    Surah(
      id: 108,
      name: 'Al-Kawthar',
      arabic: 'الكوثر',
      verses: 3,
      place: 'Meccan',
    ),
    Surah(
      id: 109,
      name: 'Al-Kafirun',
      arabic: 'الكافرون',
      verses: 6,
      place: 'Meccan',
    ),
    Surah(
      id: 110,
      name: 'An-Nasr',
      arabic: 'النصر',
      verses: 3,
      place: 'Medinan',
    ),
    Surah(
      id: 111,
      name: 'Al-Masad',
      arabic: 'المسد',
      verses: 5,
      place: 'Meccan',
    ),
    Surah(
      id: 112,
      name: 'Al-Ikhlas',
      arabic: 'الإخلاص',
      verses: 4,
      place: 'Meccan',
    ),
    Surah(
      id: 113,
      name: 'Al-Falaq',
      arabic: 'الفلق',
      verses: 5,
      place: 'Meccan',
    ),
    Surah(id: 114, name: 'An-Nas', arabic: 'الناس', verses: 6, place: 'Meccan'),
  ];

  Future<List<Surah>> loadAllSurahs() async {
    final bundled = await _loadBundledSurahIndex();
    if (bundled.isNotEmpty) {
      await _hive.settingsBox.put(
        'surah_cache',
        bundled
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'arabic': s.arabic,
                'verses': s.verses,
                'place': s.place,
              },
            )
            .toList(growable: false),
      );
      return bundled;
    }

    final client = ApiClient();
    final response = await client.get('https://api.alquran.cloud/v1/surah');
    if (response.isSuccess) {
      final rawData = response.data?['data'];
      if (rawData is List) {
        final parsed = rawData
            .whereType<Map>()
            .map(
              (item) => Surah(
                id: (item['number'] as num?)?.toInt() ?? 0,
                name: (item['englishName'] as String?) ?? 'Unknown',
                arabic: (item['name'] as String?) ?? 'Unknown',
                verses: (item['numberOfAyahs'] as num?)?.toInt() ?? 0,
                place: ((item['revelationType'] as String?) ?? 'Unknown')
                    .replaceAll('Meccan', 'Meccan')
                    .replaceAll('Medinan', 'Medinan'),
              ),
            )
            .where((item) => item.id > 0)
            .toList(growable: false);

        if (parsed.isNotEmpty) {
          await _hive.settingsBox.put(
            'surah_cache',
            parsed
                .map(
                  (s) => {
                    'id': s.id,
                    'name': s.name,
                    'arabic': s.arabic,
                    'verses': s.verses,
                    'place': s.place,
                  },
                )
                .toList(growable: false),
          );
          return parsed;
        }
      }
    }

    final cached = _hive.settingsBox.get('surah_cache');
    if (cached is List) {
      final fromCache = cached
          .whereType<Map>()
          .map(
            (item) => Surah(
              id: (item['id'] as num?)?.toInt() ?? 0,
              name: (item['name'] as String?) ?? 'Unknown',
              arabic: (item['arabic'] as String?) ?? 'Unknown',
              verses: (item['verses'] as num?)?.toInt() ?? 0,
              place: (item['place'] as String?) ?? 'Unknown',
            ),
          )
          .where((item) => item.id > 0)
          .toList(growable: false);
      if (fromCache.isNotEmpty) {
        return fromCache;
      }
    }

    return allSurahs;
  }

  Future<List<Surah>> _loadBundledSurahIndex() async {
    try {
      final raw = await rootBundle.loadString('assets/quran/surah_index.json');
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final parsed = decoded
          .whereType<Map>()
          .map(
            (item) => Surah(
              id: (item['number'] as num?)?.toInt() ?? 0,
              name: (item['englishName'] as String?) ?? 'Unknown',
              arabic: (item['name'] as String?) ?? 'Unknown',
              verses: (item['numberOfAyahs'] as num?)?.toInt() ?? 0,
              place: (item['revelationType'] as String?) ?? 'Unknown',
            ),
          )
          .where((item) => item.id > 0)
          .toList(growable: false);
      return parsed;
    } on Exception {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  List<Surah> search(String query) {
    if (query.trim().isEmpty) return allSurahs;
    final q = query.toLowerCase();
    return allSurahs.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.arabic.contains(query) ||
          '${s.id}'.contains(q);
    }).toList();
  }

  Future<void> bookmarkSurah(Surah surah) async {
    await _hive.bookmarksBox.put('${surah.id}', {
      'id': surah.id,
      'name': surah.name,
      'arabic': surah.arabic,
      'verses': surah.verses,
      'place': surah.place,
    });
  }

  Future<void> markRecent(Surah surah) async {
    await _hive.recentlyReadBox.put('last', {
      'id': surah.id,
      'name': surah.name,
      'arabic': surah.arabic,
      'verses': surah.verses,
      'place': surah.place,
      'ayahNumber': 1,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateRecentAyah({
    required Surah surah,
    required int ayahNumber,
  }) async {
    await _hive.recentlyReadBox.put('last', {
      'id': surah.id,
      'name': surah.name,
      'arabic': surah.arabic,
      'verses': surah.verses,
      'place': surah.place,
      'ayahNumber': ayahNumber,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<dynamic, dynamic>? getRecent() {
    return _hive.recentlyReadBox.get('last') as Map<dynamic, dynamic>?;
  }

  Surah surahById(int id) {
    return allSurahs.firstWhere(
      (surah) => surah.id == id,
      orElse: () => allSurahs.first,
    );
  }

  Future<QuranSurahDetail> loadSurahDetail(int surahId) async {
    final api = ApiClient();
    final results = await Future.wait([
      api.get('https://api.alquran.cloud/v1/surah/$surahId/quran-uthmani'),
      api.get('https://api.alquran.cloud/v1/surah/$surahId/en.asad'),
      api.get('https://api.alquran.cloud/v1/surah/$surahId/bn.bengali'),
      api.get('https://api.alquran.cloud/v1/surah/$surahId/ar.alafasy'),
    ]);

    if (results.every((item) => item.isSuccess)) {
      final arabicData = results[0].data?['data'] as Map?;
      final englishData = results[1].data?['data'] as Map?;
      final banglaData = results[2].data?['data'] as Map?;
      final audioData = results[3].data?['data'] as Map?;
      if (arabicData != null &&
          englishData != null &&
          banglaData != null &&
          audioData != null) {
        final arabicAyahs = ((arabicData['ayahs'] as List?) ?? const [])
            .whereType<Map>()
            .toList(growable: false);
        final englishAyahs = ((englishData['ayahs'] as List?) ?? const [])
            .whereType<Map>()
            .toList(growable: false);
        final banglaAyahs = ((banglaData['ayahs'] as List?) ?? const [])
            .whereType<Map>()
            .toList(growable: false);
        final audioAyahs = ((audioData['ayahs'] as List?) ?? const [])
            .whereType<Map>()
            .toList(growable: false);

        final length = [
          arabicAyahs.length,
          englishAyahs.length,
          banglaAyahs.length,
          audioAyahs.length,
        ].reduce((value, element) => value < element ? value : element);
        if (length > 0) {
          final surah = Surah(
            id: (arabicData['number'] as num?)?.toInt() ?? surahId,
            name:
                (arabicData['englishName'] as String?) ??
                surahById(surahId).name,
            arabic:
                (arabicData['name'] as String?) ?? surahById(surahId).arabic,
            verses: (arabicData['numberOfAyahs'] as num?)?.toInt() ?? length,
            place:
                (arabicData['revelationType'] as String?) ??
                surahById(surahId).place,
          );
          final detail = QuranSurahDetail(
            surah: surah,
            englishNameTranslation:
                (arabicData['englishNameTranslation'] as String?) ?? '',
            reciterName: 'Mishary Alafasy',
            ayahs: List<QuranAyahDetail>.generate(length, (index) {
              final arabicAyah = arabicAyahs[index];
              final englishAyah = englishAyahs[index];
              final banglaAyah = banglaAyahs[index];
              final audioAyah = audioAyahs[index];
              return QuranAyahDetail(
                numberInSurah:
                    (arabicAyah['numberInSurah'] as num?)?.toInt() ??
                    (index + 1),
                arabicText: (arabicAyah['text'] as String?) ?? '',
                englishTranslation: (englishAyah['text'] as String?) ?? '',
                banglaTranslation: (banglaAyah['text'] as String?) ?? '',
                audioUrl: (audioAyah['audio'] as String?) ?? '',
              );
            }),
          );
          await _hive.settingsBox.put('surah_detail_$surahId', detail.toJson());
          return detail;
        }
      }
    }

    final cached = _hive.settingsBox.get('surah_detail_$surahId');
    if (cached is Map) {
      return QuranSurahDetail.fromJson(cached);
    }

    final fallback = surahById(surahId);
    return QuranSurahDetail(
      surah: fallback,
      englishNameTranslation: '',
      reciterName: 'Mishary Alafasy',
      ayahs: const [],
    );
  }
}
