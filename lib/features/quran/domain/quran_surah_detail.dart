import 'package:islam/features/quran/domain/surah.dart';

class QuranAyahDetail {
  const QuranAyahDetail({
    required this.numberInSurah,
    required this.arabicText,
    required this.englishTranslation,
    required this.banglaTranslation,
    required this.audioUrl,
  });

  final int numberInSurah;
  final String arabicText;
  final String englishTranslation;
  final String banglaTranslation;
  final String audioUrl;

  Map<String, dynamic> toJson() {
    return {
      'numberInSurah': numberInSurah,
      'arabicText': arabicText,
      'englishTranslation': englishTranslation,
      'banglaTranslation': banglaTranslation,
      'audioUrl': audioUrl,
    };
  }

  factory QuranAyahDetail.fromJson(Map<dynamic, dynamic> json) {
    return QuranAyahDetail(
      numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 0,
      arabicText: (json['arabicText'] as String?) ?? '',
      englishTranslation: (json['englishTranslation'] as String?) ?? '',
      banglaTranslation: (json['banglaTranslation'] as String?) ?? '',
      audioUrl: (json['audioUrl'] as String?) ?? '',
    );
  }
}

class QuranSurahDetail {
  const QuranSurahDetail({
    required this.surah,
    required this.ayahs,
    required this.englishNameTranslation,
    required this.reciterName,
  });

  final Surah surah;
  final List<QuranAyahDetail> ayahs;
  final String englishNameTranslation;
  final String reciterName;

  Map<String, dynamic> toJson() {
    return {
      'surah': surah.toJson(),
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(growable: false),
      'englishNameTranslation': englishNameTranslation,
      'reciterName': reciterName,
    };
  }

  factory QuranSurahDetail.fromJson(Map<dynamic, dynamic> json) {
    return QuranSurahDetail(
      surah: Surah.fromJson((json['surah'] as Map?) ?? const {}),
      ayahs: ((json['ayahs'] as List?) ?? const [])
          .whereType<Map>()
          .map(QuranAyahDetail.fromJson)
          .toList(growable: false),
      englishNameTranslation: (json['englishNameTranslation'] as String?) ?? '',
      reciterName: (json['reciterName'] as String?) ?? 'Mishary Alafasy',
    );
  }
}
