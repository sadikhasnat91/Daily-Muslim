// quran_browser_screen.dart
//
// Muslim Daily – World-Class 3D Animated Quran Browser screen.
// Responsive for phone, tablet, and desktop with Arabic calligraphy and instant search.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/quran/data/quran_repository.dart';

class RecentSurah {
  final String number;
  final String name;
  final String meta;

  const RecentSurah({
    required this.number,
    required this.name,
    required this.meta,
  });
}

class SurahListItem {
  final int number;
  final String name;
  final String subtitle;
  final String arabicName;

  const SurahListItem({
    required this.number,
    required this.name,
    required this.subtitle,
    required this.arabicName,
  });
}

class JuzItem {
  final int number;
  final String name;
  final String arabicName;
  final String startInfo;
  final int startingSurahId;

  const JuzItem({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.startInfo,
    required this.startingSurahId,
  });
}

const List<JuzItem> kAllJuz = [
  JuzItem(number: 1, name: 'Al-Fatiha', arabicName: 'الم', startInfo: 'Al-Fatiha 1:1', startingSurahId: 1),
  JuzItem(number: 2, name: 'Sayaqool', arabicName: 'سَيَقُولُ', startInfo: 'Al-Baqarah 2:142', startingSurahId: 2),
  JuzItem(number: 3, name: 'Tilkal Rusul', arabicName: 'تِلْكَ الرُّسُلُ', startInfo: 'Al-Baqarah 2:253', startingSurahId: 2),
  JuzItem(number: 4, name: 'Lan Tana Lu', arabicName: 'لَنْ تَنَالُوا', startInfo: 'Ali \'Imran 3:92', startingSurahId: 3),
  JuzItem(number: 5, name: 'Wal Mohsanat', arabicName: 'وَالْمُحْصَنَاتُ', startInfo: 'An-Nisa 4:24', startingSurahId: 4),
  JuzItem(number: 6, name: 'La Yuhibbullah', arabicName: 'لَا يُحِبُّ اللَّهُ', startInfo: 'An-Nisa 4:148', startingSurahId: 4),
  JuzItem(number: 7, name: 'Wa Iza Samiu', arabicName: 'وَإِذَا سَمِعُوا', startInfo: 'Al-Ma\'idah 5:82', startingSurahId: 5),
  JuzItem(number: 8, name: 'Wa Lau Annana', arabicName: 'وَلَوْ أَنَّنَا', startInfo: 'Al-An\'am 6:111', startingSurahId: 6),
  JuzItem(number: 9, name: 'Qalal Malao', arabicName: 'قَالَ الْمَلَأُ', startInfo: 'Al-A\'raf 7:88', startingSurahId: 7),
  JuzItem(number: 10, name: 'Wa A\'lamu', arabicName: 'وَاعْلَمُوا', startInfo: 'Al-Anfal 8:41', startingSurahId: 8),
  JuzItem(number: 11, name: 'Yatazeroon', arabicName: 'يَعْتَذِرُونَ', startInfo: 'At-Tawbah 9:93', startingSurahId: 9),
  JuzItem(number: 12, name: 'Wa Mamin Da\'abat', arabicName: 'وَمَا مِنْ دَابَّةٍ', startInfo: 'Hud 11:6', startingSurahId: 11),
  JuzItem(number: 13, name: 'Wa Ma Ubarri\'o', arabicName: 'وَمَا أُبَرِّئُ', startInfo: 'Yusuf 12:53', startingSurahId: 12),
  JuzItem(number: 14, name: 'Rubama', arabicName: 'رُبَمَا', startInfo: 'Al-Hijr 15:1', startingSurahId: 15),
  JuzItem(number: 15, name: 'Subhanallazi', arabicName: 'سُبْحَانَ الَّذِي', startInfo: 'Al-Isra 17:1', startingSurahId: 17),
  JuzItem(number: 16, name: 'Qal Alam', arabicName: 'قَالَ أَلَمْ', startInfo: 'Al-Kahf 18:75', startingSurahId: 18),
  JuzItem(number: 17, name: 'Iqtaraba', arabicName: 'اقْتَرَبَ', startInfo: 'Al-Anbiya 21:1', startingSurahId: 21),
  JuzItem(number: 18, name: 'Qad Aflaha', arabicName: 'قَدْ أَفْلَحَ', startInfo: 'Al-Mu\'minun 23:1', startingSurahId: 23),
  JuzItem(number: 19, name: 'Wa Qalallazina', arabicName: 'وَقَالَ الَّذِينَ', startInfo: 'Al-Furqan 25:21', startingSurahId: 25),
  JuzItem(number: 20, name: 'A\'man Khalaqa', arabicName: 'أَمَّنْ خَلَقَ', startInfo: 'An-Naml 27:56', startingSurahId: 27),
  JuzItem(number: 21, name: 'Utlu Ma Oohiya', arabicName: 'اتْلُ مَا أُوحِيَ', startInfo: 'Al-\'Ankabut 29:45', startingSurahId: 29),
  JuzItem(number: 22, name: 'Wa Manyaqnut', arabicName: 'وَمَنْ يَقْنُتْ', startInfo: 'Al-Ahzab 33:31', startingSurahId: 33),
  JuzItem(number: 23, name: 'Wa Mali', arabicName: 'وَمَا لِيَ', startInfo: 'Ya-Sin 36:28', startingSurahId: 36),
  JuzItem(number: 24, name: 'Faman Azlam', arabicName: 'فَمَنْ أَظْلَمُ', startInfo: 'Az-Zumar 39:32', startingSurahId: 39),
  JuzItem(number: 25, name: 'Elahe Yuruddo', arabicName: 'إِلَيْهِ يُرَدُّ', startInfo: 'Fussilat 41:47', startingSurahId: 41),
  JuzItem(number: 26, name: 'Ha\'a Meem', arabicName: 'حم', startInfo: 'Al-Ahqaf 46:1', startingSurahId: 46),
  JuzItem(number: 27, name: 'Qala Fama Khatbukum', arabicName: 'قَالَ فَمَا خَطْبُكُمْ', startInfo: 'Adh-Dhariyat 51:31', startingSurahId: 51),
  JuzItem(number: 28, name: 'Qadd Sami Allah', arabicName: 'قَدْ سَمِعَ اللَّهُ', startInfo: 'Al-Mujadila 58:1', startingSurahId: 58),
  JuzItem(number: 29, name: 'Tabarakallazi', arabicName: 'تَبَارَكَ الَّذِي', startInfo: 'Al-Mulk 67:1', startingSurahId: 67),
  JuzItem(number: 30, name: 'Amma Yatasa\'aloon', arabicName: 'عَمَّ يَتَسَاءَلُونَ', startInfo: 'An-Naba 78:1', startingSurahId: 78),
];

class QuranBrowserScreen extends StatefulWidget {
  const QuranBrowserScreen({super.key});

  @override
  State<QuranBrowserScreen> createState() => _QuranBrowserScreenState();
}

class _QuranBrowserScreenState extends State<QuranBrowserScreen> {
  int _selectedTab = 0;
  final _tabs = const ['Surah', 'Juz', 'Bookmarks', 'Downloads'];
  String _searchQuery = '';

  final QuranRepository _quranRepository = QuranRepository(
    HiveService.instance,
  );

  final List<RecentSurah> _recent = [];
  final List<SurahListItem> _allSurahs = [];
  final List<SurahListItem> _bookmarks = [];
  final List<SurahListItem> _downloads = [];

  List<SurahListItem> get _visibleSurahs {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _allSurahs;
    return _allSurahs
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q) ||
            item.arabicName.contains(_searchQuery) ||
            '${item.number}'.contains(q))
        .toList(growable: false);
  }

  List<JuzItem> get _visibleJuz {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return kAllJuz;
    return kAllJuz
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            item.arabicName.contains(_searchQuery) ||
            item.startInfo.toLowerCase().contains(q) ||
            '${item.number}'.contains(q))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadBookmarks() {
    final box = HiveService.instance.bookmarksBox;
    final list = <SurahListItem>[];
    for (final raw in box.values) {
      if (raw is Map) {
        final id = (raw['id'] as num?)?.toInt() ?? 0;
        final name = (raw['name'] as String?) ?? 'Surah';
        final arabic = (raw['arabic'] as String?) ?? '';
        final verses = (raw['verses'] as num?)?.toInt() ?? 0;
        final place = (raw['place'] as String?) ?? '';
        list.add(
          SurahListItem(
            number: id,
            name: name,
            subtitle: '$place • $verses Verses',
            arabicName: arabic,
          ),
        );
      }
    }
    _bookmarks
      ..clear()
      ..addAll(list);
  }

  void _loadDownloads() {
    final box = HiveService.instance.settingsBox;
    final list = <SurahListItem>[];
    for (final key in box.keys) {
      if (key is String && key.startsWith('surah_detail_')) {
        final raw = box.get(key);
        if (raw is Map) {
          final surah = raw['surah'] as Map?;
          if (surah != null) {
            final id = (surah['id'] as num?)?.toInt() ?? 0;
            final name = (surah['name'] as String?) ?? 'Surah';
            final arabic = (surah['arabic'] as String?) ?? '';
            final verses = (surah['verses'] as num?)?.toInt() ?? 0;
            final place = (surah['place'] as String?) ?? '';
            list.add(
              SurahListItem(
                number: id,
                name: name,
                subtitle: '$place • $verses Verses (Offline Cached)',
                arabicName: arabic,
              ),
            );
          }
        }
      }
    }
    _downloads
      ..clear()
      ..addAll(list);
  }

  Future<void> _loadData() async {
    final loaded = await _quranRepository.loadAllSurahs();
    final surahs = loaded
        .map(
          (item) => SurahListItem(
            number: item.id,
            name: item.name,
            subtitle: '${item.place} • ${item.verses} Verses',
            arabicName: item.arabic,
          ),
        )
        .toList(growable: false);
    _allSurahs
      ..clear()
      ..addAll(surahs);

    _loadBookmarks();
    _loadDownloads();

    final recent = _quranRepository.getRecent();
    _recent
      ..clear()
      ..addAll([
        const RecentSurah(
          number: 'Surah 36',
          name: 'Ya-Sin',
          meta: 'Meccan • 83 Verses',
        ),
        const RecentSurah(
          number: 'Surah 18',
          name: 'Al-Kahf',
          meta: 'Meccan • 110 Verses',
        ),
        const RecentSurah(
          number: 'Surah 67',
          name: 'Al-Mulk',
          meta: 'Meccan • 30 Verses',
        ),
      ]);
    if (recent != null) {
      final id = recent['id'];
      final name = recent['name'];
      final place = recent['place'];
      final verses = recent['verses'];
      if (id is int && name is String && place is String && verses is int) {
        _recent.insert(
          0,
          RecentSurah(
            number: 'Surah $id',
            name: name,
            meta: '$place • $verses Verses',
          ),
        );
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtmosphericBackground(
        child: Stack(
          children: [
            Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
                isDesktop ? 96 : 88,
                isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
                isDesktop ? 32 : 112,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchAndTabs(
                        isDesktop: isDesktop,
                        tabs: _tabs,
                        selected: _selectedTab,
                        onSelect: (i) {
                          setState(() => _selectedTab = i);
                          if (i == 2) _loadBookmarks();
                          if (i == 3) _loadDownloads();
                        },
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_selectedTab == 0) ...[
                        const _SectionLabel('CONTINUE READING'),
                        const SizedBox(height: 12),
                        const _ContinueReadingHero(),
                        const SizedBox(height: 24),
                        const _SectionLabel('RECENTLY ACCESSED'),
                        const SizedBox(height: 12),
                        _RecentScrollRow(items: _recent, isDesktop: isDesktop),
                        const SizedBox(height: 28),
                        const _SectionLabel('ALL 114 SURAHS'),
                        const SizedBox(height: 12),
                        _SurahList(items: _visibleSurahs),
                      ] else if (_selectedTab == 1) ...[
                        const _SectionLabel('30 JUZ (PARA)'),
                        const SizedBox(height: 12),
                        _JuzList(items: _visibleJuz),
                      ] else if (_selectedTab == 2) ...[
                        const _SectionLabel('SAVED BOOKMARKS'),
                        const SizedBox(height: 12),
                        _BookmarksList(
                          items: _bookmarks,
                          onDelete: (id) async {
                            await HiveService.instance.bookmarksBox
                                .delete('$id');
                            setState(() => _loadBookmarks());
                          },
                        ),
                      ] else ...[
                        const _SectionLabel('OFFLINE CACHED SURAHS'),
                        const SizedBox(height: 12),
                        _DownloadsList(items: _downloads),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _QuranHeader(isDesktop: isDesktop),
          ),

          if (!isDesktop)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.quran),
            ),
        ],
      ),
    ),
  );
}
}

class _QuranHeader extends StatelessWidget {
  final bool isDesktop;
  const _QuranHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalMargin(context),
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.75),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'The Holy Qur\'an',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
                ScaleButton(
                  onTap: () => UiActions.openSearch(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}

class _SearchAndTabs extends StatelessWidget {
  final bool isDesktop;
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onSearchChanged;

  const _SearchAndTabs({
    required this.isDesktop,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3D Glass Search Input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.plusJakartaSans(color: AppColors.onBackground),
            decoration: InputDecoration(
              hintText: 'Search Surah by name, number or Arabic...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainer.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3D Sliding Tabs Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ScaleButton(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: selected == i
                            ? AppColors.primaryGradient
                            : null,
                        color: selected == i
                            ? null
                            : AppColors.surfaceContainerHigh.withOpacity(0.7),
                        border: Border.all(
                          color: selected == i
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                        boxShadow: selected == i
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tabs[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected == i
                              ? AppColors.onPrimary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingHero extends StatelessWidget {
  const _ContinueReadingHero();

  @override
  Widget build(BuildContext context) {
    final recent = HiveService.instance.recentlyReadBox.get('last') as Map?;
    final recentName = (recent?['name'] as String?) ?? 'Al-Baqarah';
    final verseNumber = (recent?['ayahNumber'] as int?) ?? 1;
    final recentId = (recent?['id'] as int?) ?? 2;

    return Card3D(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      onTap: () => UiActions.openQuranReader(context, surahId: recentId),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_added_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LAST READ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Surah $recentName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ayah $verseNumber • Tap to resume recitation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScrollRow extends StatelessWidget {
  final List<RecentSurah> items;
  final bool isDesktop;

  const _RecentScrollRow({
    required this.items,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: items.map((item) {
          final surahNum = int.tryParse(item.number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ScaleButton(
              onTap: () => UiActions.openQuranReader(context, surahId: surahNum),
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF16231C), Color(0xFF0F1813)],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.meta,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  final List<SurahListItem> items;
  const _SurahList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No Surahs match your search.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurahRow(item: item),
          ),
      ],
    );
  }
}

class _SurahRow extends StatelessWidget {
  final SurahListItem item;
  const _SurahRow({required this.item});

  (String place, int verses) _parseMeta() {
    final parts = item.subtitle.split('•').map((p) => p.trim()).toList();
    final place = parts.isEmpty ? 'Unknown' : parts.first;
    final versesPart = parts.length > 1 ? parts.last : '';
    final verses =
        int.tryParse(versesPart.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return (place, verses);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: () async {
        final (place, verses) = _parseMeta();
        await UiActions.markRecentSurah(
          context,
          id: item.number,
          name: item.name,
          arabic: item.arabicName,
          verses: verses,
          place: place,
        );
        if (context.mounted) {
          UiActions.openQuranReader(context, surahId: item.number);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceContainer.withOpacity(0.8),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            // 3D Number Octagon/Circle Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3226), Color(0xFF121F17)],
                ),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${item.number}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.arabicName,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  final List<JuzItem> items;
  const _JuzList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ScaleButton(
              onTap: () => UiActions.openQuranReader(context, surahId: item.startingSurahId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surfaceContainer.withOpacity(0.8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant.withOpacity(0.5),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${item.number}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Juz ${item.number} • ${item.name}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Starts at ${item.startInfo}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.arabicName,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BookmarksList extends StatelessWidget {
  final List<SurahListItem> items;
  final ValueChanged<int> onDelete;

  const _BookmarksList({
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No saved bookmarks yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.surfaceContainer.withOpacity(0.8),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: () => UiActions.openQuranReader(context, surahId: item.number),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onDelete(item.number),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DownloadsList extends StatelessWidget {
  final List<SurahListItem> items;
  const _DownloadsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Read any surah once to cache it offline.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurahRow(item: item),
          ),
      ],
    );
  }
}
