import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_service.dart';

final duaRepositoryProvider = Provider<DuaRepository>((_) {
  return DuaRepository(HiveService.instance);
});

class DuaModel {
  final String id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String banglaTranslation;
  final String englishTranslation;
  final String reference;

  const DuaModel({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.banglaTranslation,
    required this.englishTranslation,
    required this.reference,
  });
}

class DuaRepository {
  DuaRepository(this._hive);

  final HiveService _hive;

  final categories = const [
    'Morning / Evening',
    'Sleep',
    'Travel',
    'Forgiveness',
    'Health',
    'Success',
  ];

  static const List<DuaModel> allDuas = [
    // Morning / Evening
    DuaModel(
      id: 'me_1',
      category: 'Morning / Evening',
      title: 'Sayyidul Istighfar (Master of Forgiveness)',
      arabic:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      transliteration:
          'Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana \'abduka, wa ana \'ala \'ahdika wa wa\'dika mastata\'tu, a\'udhu bika min sharri ma sana\'tu, abu\'u laka bini\'matika \'alayya, wa abu\'u bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa Anta.',
      banglaTranslation:
          'হে আল্লাহ! আপনি আমার রব, আপনি ছাড়া কোনো উপাস্য নেই। আপনি আমাকে সৃষ্টি করেছেন এবং আমি আপনার বান্দা। আমি আমার সাধ্যমত আপনার অঙ্গীকারে ও প্রতিজ্ঞায় অটল রয়েছি। আমি আমার কৃতকর্মের অনিষ্ট থেকে আপনার আশ্রয় চাই। আমার প্রতি আপনার অনুগ্রহ স্বীকার করছি এবং আমার পাপও স্বীকার করছি। অতএব আমাকে ক্ষমা করুন, কারণ আপনি ছাড়া আর কেউ পাপ ক্ষমা করতে পারে না।',
      englishTranslation:
          'O Allah! You are my Lord, none has the right to be worshipped but You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favors upon me and I acknowledge my sin, so forgive me, for none forgives sins except You.',
      reference: 'Sahih Bukhari: 6306',
    ),
    DuaModel(
      id: 'me_2',
      category: 'Morning / Evening',
      title: 'Protection from All Harm',
      arabic:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      transliteration:
          'Bismillahil-ladhi la yadurru ma\'as-mihi shay\'un fil-ardi wa la fis-sama\'i wa Huwas-Sami\'ul-\'Alim.',
      banglaTranslation:
          'আল্লাহর নামে, যাঁর নামের বরকতে আসমান ও জমিনের কোনো কিছুই কোনো ক্ষতি করতে পারে না। আর তিনি সর্বশ্রোতা, সর্বজ্ঞানী। (সকাল-সন্ধ্যায় ৩ বার)',
      englishTranslation:
          'In the Name of Allah, with Whose Name nothing upon earth or in the heavens causes harm, and He is the All-Hearing, the All-Knowing. (Recite 3 times)',
      reference: 'Abu Dawud: 5088, Tirmidhi: 3388',
    ),
    DuaModel(
      id: 'me_3',
      category: 'Morning / Evening',
      title: 'Morning Supplication for Sovereignty & Praise',
      arabic:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration:
          'Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah.',
      banglaTranslation:
          'আমরা সকালে উপনীত হয়েছি এবং সকল রাজত্বও সকাল বেলা আল্লাহর জন্য হয়ে গেছে। সমস্ত প্রশংসা আল্লাহর। এক আল্লাহ ছাড়া আর কোনো মাবুদ নেই, তাঁর কোনো শরিক নেই।',
      englishTranslation:
          'We have reached the morning and the kingdom belongs to Allah, all praise is for Allah. None has the right to be worshipped except Allah alone, without partner.',
      reference: 'Sahih Muslim: 2723',
    ),

    // Sleep
    DuaModel(
      id: 'sl_1',
      category: 'Sleep',
      title: 'Dua Before Sleeping',
      arabic: 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
      transliteration: 'Allahumma bismika amutu wa ahya.',
      banglaTranslation: 'হে আল্লাহ! আপনারই নামে আমি মৃত্যুবরণ করি (ঘুমাই) এবং জীবিত হই (জাগ্রত হই)।',
      englishTranslation: 'O Allah, in Your name I die and I live.',
      reference: 'Sahih Bukhari: 6324',
    ),
    DuaModel(
      id: 'sl_2',
      category: 'Sleep',
      title: 'Dua Upon Waking Up',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration:
          'Alhamdu lillahilladhi ahyana ba\'da ma amatana wa ilayhin-nushur.',
      banglaTranslation:
          'সমস্ত প্রশংসা সেই আল্লাহর জন্য, যিনি আমাদের মৃত্যুর পর পুনরায় জীবিত করলেন এবং তাঁর দিকেই আমাদের পুনরুত্থান।',
      englishTranslation:
          'All praise is for Allah Who gave us life after having taken it from us, and unto Him is the resurrection.',
      reference: 'Sahih Bukhari: 6312',
    ),
    DuaModel(
      id: 'sl_3',
      category: 'Sleep',
      title: 'Ayat al-Kursi (Bedtime Protection)',
      arabic:
          'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
      transliteration:
          'Allahu la ilaha illa Huwal-Hayyul-Qayyum. La ta\'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard...',
      banglaTranslation:
          'আল্লাহ, তিনি ছাড়া কোনো সত্য উপাস্য নেই। তিনি চিরঞ্জীব, চিরস্থায়ী। তন্দ্রা বা ঘুম তাঁকে স্পর্শ করতে পারে না। আকাশমণ্ডল ও পৃথিবীতে যা কিছু আছে সবই তাঁর।',
      englishTranslation:
          'Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep...',
      reference: 'Surah Al-Baqarah 2:255',
    ),

    // Travel
    DuaModel(
      id: 'tr_1',
      category: 'Travel',
      title: 'Dua for Riding a Vehicle / Traveling',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
      transliteration:
          'Subhanalladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun.',
      banglaTranslation:
          'পবিত্র ও মহান সেই সত্তা, যিনি এটাকে আমাদের বশীভূত করে দিয়েছেন, অথচ আমরা এটাকে বশীভূত করতে পারতাম না। আর নিশ্চয়ই আমরা আমাদের রবের দিকেই ফিরে যাব।',
      englishTranslation:
          'Glory be to Him Who has subjected this to us, and we could never have it by our efforts. And verily, to our Lord we shall return.',
      reference: 'Surah Az-Zukhruf 43:13-14',
    ),
    DuaModel(
      id: 'tr_2',
      category: 'Travel',
      title: 'Dua When Leaving the House',
      arabic:
          'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration:
          'Bismillahi tawakkaltu \'alallah, wa la hawla wa la quwwata illa billah.',
      banglaTranslation:
          'আল্লাহর নামে, আমি আল্লাহর ওপর ভরসা করলাম। আল্লাহর সাহায্য ছাড়া কোনো অনিষ্ট দূর করার বা কোনো ভালো কাজ করার শক্তি নেই।',
      englishTranslation:
          'In the Name of Allah, I trust in Allah; there is no might and no power but in Allah.',
      reference: 'Abu Dawud: 5095, Tirmidhi: 3426',
    ),

    // Forgiveness
    DuaModel(
      id: 'fg_1',
      category: 'Forgiveness',
      title: 'Dua of Prophet Yunus (Dua-e-Yunus)',
      arabic: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      transliteration: 'La ilaha illa Anta subhanaka inni kuntu minaz-zalimin.',
      banglaTranslation:
          'তুমি ছাড়া কোনো সত্য উপাস্য নেই, তুমি পবিত্র-মহান! নিশ্চয়ই আমি জালিমদের অন্তর্ভুক্ত ছিলাম।',
      englishTranslation:
          'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
      reference: 'Surah Al-Anbiya 21:87',
    ),
    DuaModel(
      id: 'fg_2',
      category: 'Forgiveness',
      title: 'Dua of Adam and Hawwa for Mercy',
      arabic:
          'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      transliteration:
          'Rabbana zalamna anfusana wa il-lam taghfir lana wa tarhamna lanakunanna minal-khasirin.',
      banglaTranslation:
          'হে আমাদের প্রতিপালক! আমরা নিজেদের ওপর অন্যায় করেছি। আর যদি আপনি আমাদের ক্ষমা না করেন এবং আমাদের প্রতি দয়া না করেন, তবে অবশ্যই আমরা ক্ষতিগ্রস্তদের অন্তর্ভুক্ত হয়ে যাব।',
      englishTranslation:
          'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
      reference: 'Surah Al-A\'raf 7:23',
    ),

    // Health
    DuaModel(
      id: 'hl_1',
      category: 'Health',
      title: 'Dua for Pain in the Body',
      arabic:
          'بِسْمِ اللَّهِ (৩ বার), أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ (৭ বার)',
      transliteration:
          'Bismillah (3x), A\'udhu billahi wa qudratihi min sharri ma ajidu wa uhadhir (7x).',
      banglaTranslation:
          'আল্লাহর নামে (৩ বার)। আল্লাহর এবং তাঁর কুদরতের আশ্রয় প্রার্থনা করছি যা কিছু আমি অনুভব করছি এবং যার আশঙ্কা করছি তার অনিষ্ট থেকে। (৭ বার ব্যথার স্থানে হাত রেখে)',
      englishTranslation:
          'In the name of Allah (3 times). I seek refuge in Allah and His Power from the evil of what I find and fear. (7 times placing hand on pain)',
      reference: 'Sahih Muslim: 2202',
    ),
    DuaModel(
      id: 'hl_2',
      category: 'Health',
      title: 'Supplication for Comprehensive Well-being',
      arabic:
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ',
      transliteration:
          'Allahumma \'afini fi badani, Allahumma \'afini fi sam\'i, Allahumma \'afini fi basari, la ilaha illa Ant.',
      banglaTranslation:
          'হে আল্লাহ! আমার দেহে সুস্থতা দান করুন। হে আল্লাহ! আমার শ্রবণশক্তিতে সুস্থতা দান করুন। হে আল্লাহ! আমার দৃষ্টিশক্তিতে সুস্থতা দান করুন। আপনি ছাড়া কোনো সত্য উপাস্য নেই।',
      englishTranslation:
          'O Allah, grant my body health. O Allah, grant my hearing health. O Allah, grant my sight health. None has the right to be worshipped except You.',
      reference: 'Abu Dawud: 5090',
    ),

    // Success
    DuaModel(
      id: 'sc_1',
      category: 'Success',
      title: 'Dua for Increase in Knowledge',
      arabic: 'رَبِّ زِدْنِي عِلْمًا',
      transliteration: 'Rabbi zidni \'ilma.',
      banglaTranslation: 'হে আমার রব! আমার জ্ঞান বৃদ্ধি করে দিন।',
      englishTranslation: 'My Lord, increase me in knowledge.',
      reference: 'Surah Ta-Ha 20:114',
    ),
    DuaModel(
      id: 'sc_2',
      category: 'Success',
      title: 'Dua for Making Tasks Easy',
      arabic:
          'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
      transliteration:
          'Allahumma la sahla illa ma ja\'altahu sahla, wa Anta taj\'alul-hazna idha shi\'ta sahla.',
      banglaTranslation:
          'হে আল্লাহ! আপনি যা সহজ করেছেন তা ছাড়া কোনো কিছুই সহজ নয়। আর আপনি চাইলে যেকোনো কঠিন বা দুঃখের বিষয়কে সহজ করে দেন।',
      englishTranslation:
          'O Allah, there is nothing made easy except what You make easy, and You make hardship easy if You will.',
      reference: 'Sahih Ibn Hibban: 974',
    ),
    DuaModel(
      id: 'sc_3',
      category: 'Success',
      title: 'Dua for Good in This Life and the Next',
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar.',
      banglaTranslation:
          'হে আমাদের রব! আপনি আমাদেরকে দুনিয়াতেও কল্যাণ দান করুন এবং আখেরাতেও কল্যাণ দান করুন, আর আমাদেরকে জাহান্নামের আজাব থেকে রক্ষা করুন।',
      englishTranslation:
          'Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.',
      reference: 'Surah Al-Baqarah 2:201',
    ),
  ];

  List<DuaModel> getDuasByCategory(String category) {
    return allDuas
        .where((d) => d.category.trim().toLowerCase() == category.trim().toLowerCase())
        .toList(growable: false);
  }

  List<DuaModel> searchDuas(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allDuas;
    return allDuas.where((d) {
      return d.title.toLowerCase().contains(q) ||
          d.banglaTranslation.toLowerCase().contains(q) ||
          d.englishTranslation.toLowerCase().contains(q) ||
          d.transliteration.toLowerCase().contains(q) ||
          d.arabic.contains(query) ||
          d.category.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> addFavorite(String key, Map<String, dynamic> value) async {
    await _hive.favoritesBox.put(key, value);
  }

  List<Map<dynamic, dynamic>> getFavorites() {
    return _hive.favoritesBox.values
        .whereType<Map<dynamic, dynamic>>()
        .toList(growable: false);
  }
}
