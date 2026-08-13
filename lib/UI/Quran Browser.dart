// quran_browser.dart
//
// Flutter conversion of the "Quran Browser - Muslim Daily" HTML page.
//
// Dependencies (add to pubspec.yaml):
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1
//
// Run with: flutter run -t lib/quran_browser.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/quran/data/quran_repository.dart';



/// ---------------------------------------------------------------------
/// App
/// ---------------------------------------------------------------------
class QuranBrowserApp extends StatelessWidget {
  const QuranBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Browser - Muslim Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const QuranBrowserScreen(),
    );
  }
}

/// Data models
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

  List<SurahListItem> get _visibleSurahs {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return _allSurahs;
    }
    return _allSurahs
        .where((item) {
          return item.name.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q) ||
              item.arabicName.contains(_searchQuery) ||
              '${item.number}'.contains(q);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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

    final recent = _quranRepository.getRecent();
    _recent
      ..clear()
      ..addAll([
        RecentSurah(
          number: 'Surah 36',
          name: 'Ya-Sin',
          meta: 'Meccan • 83 Verses',
        ),
        RecentSurah(
          number: 'Surah 18',
          name: 'Al-Kahf',
          meta: 'Meccan • 110 Verses',
        ),
        RecentSurah(
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

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
                        onSelect: (i) => setState(() => _selectedTab = i),
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Continue Reading'),
                      const _ContinueReadingHero(),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Recent'),
                      _RecentScrollRow(items: _recent, isDesktop: isDesktop),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('All Surahs'),
                      const SizedBox(height: 4),
                      _SurahList(items: _visibleSurahs),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: isDesktop ? const _DesktopHeader() : const _MobileHeader(),
          ),
          if (!isDesktop)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomNavBar(),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Reusable glass surface
/// ---------------------------------------------------------------------
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final Color tint;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 24,
    this.tint = const Color(0x990E1511),
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Desktop header
/// ---------------------------------------------------------------------
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    final settings =
        HiveService.instance.settingsBox.get(HiveKeys.appSettings) as Map?;
    final profileName = (settings?['profileName'] as String?) ?? 'Muslim Daily';
    final profileImageUrl = (settings?['profileImageUrl'] as String?) ?? '';
    final hasImage = profileImageUrl.startsWith('http');
    final initial = profileName.trim().isEmpty
        ? 'M'
        : profileName.trim().substring(0, 1).toUpperCase();
    return GlassSurface(
      blurSigma: 24,
      tint: AppColors.surface.withOpacity(0.6),
      border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: hasImage
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: hasImage ? null : Text(initial),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Salam, $profileName',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      height: 32 / 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => UiActions.openNotifications(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.notifications, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Mobile header
/// ---------------------------------------------------------------------
class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      blurSigma: 24,
      tint: AppColors.surface.withOpacity(0.6),
      border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quran',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.primary,
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => UiActions.openSearch(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.search, color: AppColors.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Search bar (desktop only) + tabs
/// ---------------------------------------------------------------------
class _SearchAndTabs extends StatelessWidget {
  final bool isDesktop;
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<String>? onSearchChanged;

  const _SearchAndTabs({
    required this.isDesktop,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        if (isDesktop)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 576),
              child: TextField(
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Surahs, Verses, Translations...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surface.withOpacity(0.4),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (isDesktop) const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final isSelected = i == selected;
              return _TabChip(
                label: tabs[i],
                selected: isSelected,
                onTap: () => onSelect(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.surface.withOpacity(0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              letterSpacing: 0.65,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Small uppercase section label
/// ---------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 13,
          letterSpacing: 0.65,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Continue Reading hero card
/// ---------------------------------------------------------------------
class _ContinueReadingHero extends StatelessWidget {
  const _ContinueReadingHero();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final recent = HiveService.instance.recentlyReadBox.get('last') as Map?;
    final recentName = (recent?['name'] as String?) ?? 'Al-Baqarah';
    final verseNumber = (recent?['ayahNumber'] as int?) ?? 1;
    final recentId = (recent?['id'] as int?) ?? 2;

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Last Read',
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 0.65,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          recentName,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.28,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verse $verseNumber • Continue where you left off',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );

    final playButton = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20),
        ],
      ),
      child: const Icon(Icons.play_arrow, color: AppColors.onPrimary),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => UiActions.openQuranReader(context, surahId: recentId),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -40,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [textBlock, playButton],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textBlock,
                          const SizedBox(height: AppSpacing.md),
                          playButton,
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Recently-read horizontal scroll row
/// ---------------------------------------------------------------------
class _RecentScrollRow extends StatelessWidget {
  final List<RecentSurah> items;
  final bool isDesktop;

  const _RecentScrollRow({required this.items, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => _RecentCard(item: items[i]),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final RecentSurah item;
  const _RecentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final surahNumber = int.tryParse(
      item.number.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final versesMatch = RegExp(r'([0-9]+)\s+Verses').firstMatch(item.meta);
    final verses = int.tryParse(versesMatch?.group(1) ?? '0') ?? 0;
    final place = item.meta.split('•').first.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (surahNumber != null) {
            await UiActions.markRecentSurah(
              context,
              id: surahNumber,
              name: item.name,
              arabic: item.name,
              verses: verses,
              place: place,
            );
          }
          if (context.mounted) {
            UiActions.openQuranReader(context, surahId: surahNumber ?? 1);
          }
        },
        child: GlassSurface(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.number,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        letterSpacing: 0.65,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Icon(
                      Icons.bookmark_border,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.meta,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// All Surahs list
/// ---------------------------------------------------------------------
class _SurahList extends StatelessWidget {
  final List<SurahListItem> items;
  const _SurahList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _SurahRow(item: items[i]),
          if (i != items.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 56),
              child: Divider(height: 1, color: Colors.white10),
            ),
        ],
      ],
    );
  }
}

class _SurahRow extends StatefulWidget {
  final SurahListItem item;
  const _SurahRow({required this.item});

  @override
  State<_SurahRow> createState() => _SurahRowState();
}

class _SurahRowState extends State<_SurahRow> {
  bool _hovering = false;

  (String place, int verses) _parseMeta() {
    final parts = widget.item.subtitle.split('•').map((p) => p.trim()).toList();
    final place = parts.isEmpty ? 'Unknown' : parts.first;
    final versesPart = parts.length > 1 ? parts.last : '';
    final verses =
        int.tryParse(versesPart.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return (place, verses);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final (place, verses) = _parseMeta();
            await UiActions.markRecentSurah(
              context,
              id: widget.item.number,
              name: widget.item.name,
              arabic: widget.item.arabicName,
              verses: verses,
              place: place,
            );
            if (context.mounted) {
              UiActions.openQuranReader(context, surahId: widget.item.number);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hovering ? Colors.white.withOpacity(0.05) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovering
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _hovering
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.item.number}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            letterSpacing: 0.65,
                            color: _hovering
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: _hovering
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              widget.item.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.item.arabicName,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 36,
                      color: AppColors.onSurface,
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

/// ---------------------------------------------------------------------
/// Bottom navigation bar (mobile only)
/// ---------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: GlassSurface(
        blurSigma: 24,
        tint: AppColors.surface.withOpacity(0.6),
        border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16),
        ],
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _NavItem(icon: Icons.home, label: 'Home', active: false),
                _NavItem(icon: Icons.schedule, label: 'Prayer', active: false),
                _NavItem(icon: Icons.menu_book, label: 'Quran', active: true),
                _NavItem(
                  icon: Icons.auto_awesome,
                  label: 'Duas',
                  active: false,
                ),
                _NavItem(icon: Icons.person, label: 'Profile', active: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.onSurfaceVariant.withOpacity(0.7);

    return InkWell(
      onTap: () => UiActions.openByLabel(context, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                letterSpacing: 0.65,
                color: color,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
