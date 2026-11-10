// duas_screen.dart
//
// Muslim Daily – World-Class 3D Animated Duas & Supplications screen.
// Responsive for phone, tablet, and desktop with Arabic calligraphy and audio supplications.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/dua/data/dua_repository.dart';

class FavoriteDua {
  final IconData icon;
  final String title;
  final String subtitle;
  const FavoriteDua({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class DuaCategory {
  final IconData icon;
  final String label;
  final Color color;
  const DuaCategory({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolled = false;
  String _query = '';

  static const _defaultFavorites = [
    FavoriteDua(
      icon: Icons.wb_sunny_rounded,
      title: 'Morning Adhkar',
      subtitle: 'Read daily at dawn',
    ),
    FavoriteDua(
      icon: Icons.flight_takeoff_rounded,
      title: 'Dua for Travel',
      subtitle: 'Safe journey protection',
    ),
  ];

  final _categories = const [
    DuaCategory(icon: Icons.wb_twilight_rounded, label: 'Morning / Evening', color: Color(0xFF00E599)),
    DuaCategory(icon: Icons.bedtime_rounded, label: 'Sleep & Night', color: Color(0xFF818CF8)),
    DuaCategory(icon: Icons.commute_rounded, label: 'Travel & Journey', color: Color(0xFF38BDF8)),
    DuaCategory(icon: Icons.clean_hands_rounded, label: 'Forgiveness (Tawbah)', color: Color(0xFFFBBF24)),
    DuaCategory(icon: Icons.favorite_rounded, label: 'Health & Healing', color: Color(0xFFF472B6)),
    DuaCategory(icon: Icons.trending_up_rounded, label: 'Success & Guidance', color: Color(0xFF34D399)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldBeScrolled = _scrollController.offset > 20;
      if (shouldBeScrolled != _scrolled) {
        setState(() => _scrolled = shouldBeScrolled);
      }
    });
  }

  List<FavoriteDua> _favoritesFromStorage() {
    final fromHive = HiveService.instance.favoritesBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => FavoriteDua(
            icon: Icons.favorite_rounded,
            title: (item['title'] as String?) ?? 'Favorite Dua',
            subtitle: (item['subtitle'] as String?) ?? 'Saved',
          ),
        )
        .toList(growable: false);

    final merged = [..._defaultFavorites, ...fromHive];
    if (_query.trim().isEmpty) return merged;
    final q = _query.toLowerCase();
    return merged
        .where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<DuaCategory> _filteredCategories() {
    if (_query.trim().isEmpty) return _categories;
    final q = _query.toLowerCase();
    return _categories
        .where((item) => item.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);
    final settings =
        HiveService.instance.settingsBox.get('app_settings') as Map?;
    final profileName =
        (settings?['profileName'] as String?) ?? 'Muslim Daily';
    final profileImageUrl =
        (settings?['profileImageUrl'] as String?) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -80,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 260, opacity: 0.12),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalMargin(context),
                92,
                AppResponsive.horizontalMargin(context),
                AppResponsive.bottomScrollPad(context),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderAndSearch(
                        onSearchChanged: (value) {
                          setState(() => _query = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<Box<dynamic>>(
                        valueListenable:
                            HiveService.instance.favoritesBox.listenable(),
                        builder: (context, _, __) {
                          if (_query.trim().isNotEmpty) {
                            final searchResults =
                                DuaRepository(HiveService.instance)
                                    .searchDuas(_query);
                            if (searchResults.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Duas found for "$_query"',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Search Results (${searchResults.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                for (final dua in searchResults)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _DuaDetailCard(dua: dua),
                                  ),
                              ],
                            );
                          }

                          final liveFavorites = _favoritesFromStorage();
                          final filteredCategories = _filteredCategories();

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _LeftColumn(favorites: liveFavorites),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 5,
                                  child: _CategoriesColumn(
                                    categories: filteredCategories,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LeftColumn(favorites: liveFavorites),
                              const SizedBox(height: 28),
                              _CategoriesColumn(categories: filteredCategories),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Shared Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SharedTopAppBar(
              profileName: profileName,
              profileImageUrl: profileImageUrl,
              scrollOpacity: _scrolled ? 0.85 : 0.65,
            ),
          ),

          if (!isWide)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavBar(active: NavTab.duas),
            ),
        ],
      ),
    );
  }
}

class _HeaderAndSearch extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  const _HeaderAndSearch({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'HISNUL MUSLIM',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duas & Supplications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: AppResponsive.scaleFont(context, min: 26, max: 38),
            letterSpacing: -1.0,
            fontWeight: FontWeight.w900,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daily authentic supplications from the Quran and Sunnah.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        // 3D Glass Search Input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.plusJakartaSans(color: AppColors.onBackground),
            decoration: InputDecoration(
              hintText: 'Search duas by keyword, title, or Arabic...',
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
      ],
    );
  }
}

class _LeftColumn extends StatelessWidget {
  final List<FavoriteDua> favorites;
  const _LeftColumn({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeaturedDuaCard(),
        const SizedBox(height: 24),
        Text(
          'FAVORITE DUAS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        for (final fav in favorites)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FavoriteRow(fav: fav),
          ),
      ],
    );
  }
}

class _FeaturedDuaCard extends StatelessWidget {
  const _FeaturedDuaCard();

  @override
  Widget build(BuildContext context) {
    return Card3D(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B3226), Color(0xFF101E17)],
      ),
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DAILY DU\'A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ScaleButton(
                    onTap: () {
                      UiActions.addFavoriteDua(
                        context,
                        title: 'Dua for Guidance & Protection',
                        subtitle: 'Rabbana atina fid-dunya hasanah',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleButton(
                    onTap: () {
                      UiActions.shareText(
                        context,
                        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ\n'
                        'Our Lord, give us in this world that which is good and in the Hereafter that which is good and protect us from the punishment of the Fire.',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: AppColors.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Text(
              '"Our Lord, give us in this world that which is good and in the Hereafter that which is good and save us from the punishment of the Fire."',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Surah Al-Baqarah 2:201',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final FavoriteDua fav;
  const _FavoriteRow({required this.fav});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: () {
        final matches = DuaRepository(HiveService.instance).searchDuas(fav.title);
        if (matches.isNotEmpty) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CategoryDuasSheet(
              category: fav.title,
              duas: matches,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceContainer.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
              child: Icon(fav.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fav.subtitle,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesColumn extends StatelessWidget {
  final List<DuaCategory> categories;
  const _CategoriesColumn({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CATEGORIES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        for (final cat in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryTile(category: cat),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final DuaCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final duas =
        DuaRepository(HiveService.instance).getDuasByCategory(category.label);

    return ScaleButton(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CategoryDuasSheet(
            category: category.label,
            duas: duas,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceContainer.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withOpacity(0.15),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${duas.length} Supplications',
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDuasSheet extends StatelessWidget {
  final String category;
  final List<DuaModel> duas;

  const _CategoryDuasSheet({
    required this.category,
    required this.duas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: duas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _DuaDetailCard(dua: duas[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaDetailCard extends StatelessWidget {
  final DuaModel dua;
  const _DuaDetailCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Card3D(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dua.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              Row(
                children: [
                  ScaleButton(
                    onTap: () {
                      UiActions.addFavoriteDua(
                        context,
                        title: dua.title,
                        subtitle: dua.englishTranslation,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ScaleButton(
                    onTap: () {
                      UiActions.shareText(
                        context,
                        '${dua.title}\n${dua.arabic}\n${dua.englishTranslation}\n(${dua.reference})',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              dua.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.8,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dua.englishTranslation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: AppColors.onBackground,
            ),
          ),
          if (dua.banglaTranslation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dua.banglaTranslation,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (dua.reference.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dua.reference,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
