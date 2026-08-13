// duas_screen.dart
//
// Flutter conversion of the "Muslim Daily - Duas" HTML page.
//
// Dependencies (add to pubspec.yaml):
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1
//
// Run with: flutter run -t lib/duas_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';

/// ---------------------------------------------------------------------
/// Design tokens
/// ---------------------------------------------------------------------




/// ---------------------------------------------------------------------
/// App
/// ---------------------------------------------------------------------
class DuasApp extends StatelessWidget {
  const DuasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muslim Daily - Duas',
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
      home: const DuasScreen(),
    );
  }
}

/// Data models
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
  const DuaCategory({required this.icon, required this.label});
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
      icon: Icons.wb_sunny,
      title: 'Morning Adhkar',
      subtitle: 'Read daily',
    ),
    FavoriteDua(
      icon: Icons.flight_takeoff,
      title: 'Dua for Travel',
      subtitle: 'Used 3 days ago',
    ),
  ];

  final _categories = const [
    DuaCategory(icon: Icons.repeat, label: 'Morning / Evening'),
    DuaCategory(icon: Icons.bedtime, label: 'Sleep'),
    DuaCategory(icon: Icons.commute, label: 'Travel'),
    DuaCategory(icon: Icons.clean_hands, label: 'Forgiveness'),
    DuaCategory(icon: Icons.favorite_border, label: 'Health'),
    DuaCategory(icon: Icons.trending_up, label: 'Success'),
  ];

  @override
  void initState() {
    super.initState();
    // Mirrors the JS scroll listener that darkens the TopAppBar background
    // once the page has scrolled past 20px.
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
            icon: Icons.favorite,
            title: (item['title'] as String?) ?? 'Favorite Dua',
            subtitle: (item['subtitle'] as String?) ?? 'Saved',
          ),
        )
        .toList(growable: false);

    final merged = [..._defaultFavorites, ...fromHive];
    if (_query.trim().isEmpty) {
      return merged;
    }
    final q = _query.toLowerCase();
    return merged
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<DuaCategory> _filteredCategories() {
    if (_query.trim().isEmpty) {
      return _categories;
    }
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
                      const SizedBox(height: AppSpacing.lg),
                      ValueListenableBuilder<Box<dynamic>>(
                        valueListenable: HiveService.instance.favoritesBox
                            .listenable(),
                        builder: (context, _, __) {
                          final liveFavorites = _favoritesFromStorage();
                          final filteredCategories = _filteredCategories();

                          if (isWide) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _LeftColumn(
                                      favorites: liveFavorites,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    flex: 4,
                                    child: _CategoriesColumn(
                                      categories: filteredCategories,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LeftColumn(favorites: liveFavorites),
                              const SizedBox(height: AppSpacing.md),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SharedTopAppBar(
              profileName: profileName,
              profileImageUrl: profileImageUrl,
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

// GlassSurface, _TopAppBar, _DesktopNavCluster, _NavLink
// → all replaced by shared widgets from app_theme_tokens.dart

/// Page header + search field
class _HeaderAndSearch extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;

  const _HeaderAndSearch({this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Duas',
          style: GoogleFonts.inter(
            fontSize: 48,
            height: 56 / 48,
            letterSpacing: -0.96,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find peace and guidance in daily supplications.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Search for a specific dua...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Left column: featured dua card + favorites list
/// ---------------------------------------------------------------------
class _LeftColumn extends StatelessWidget {
  final List<FavoriteDua> favorites;
  const _LeftColumn({required this.favorites});

  @override
  Widget build(BuildContext context) {
    final isWideRow = MediaQuery.of(context).size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeaturedDuaCard(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(
              Icons.favorite,
              size: 20,
              color: AppColors.tertiaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Favorites',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isWideRow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < favorites.length; i++) ...[
                Expanded(child: _FavoriteRow(item: favorites[i])),
                if (i != favorites.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          )
        else
          Column(
            children: [
              for (int i = 0; i < favorites.length; i++) ...[
                _FavoriteRow(item: favorites[i]),
                if (i != favorites.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _FeaturedDuaCard extends StatelessWidget {
  const _FeaturedDuaCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => UiActions.addFavoriteDua(
          context,
          title: 'Daily Featured',
          subtitle: 'Surah Al-Baqarah (2:201)',
        ),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 320),
            child: Stack(
              children: [
                Positioned(
                  right: -80,
                  top: -80,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(
                      width: 256,
                      height: 256,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Daily Featured',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    letterSpacing: 0.65,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.bookmark_border,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي '
                              'الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 30,
                                height: 1.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '"Our Lord, give us in this world [that which '
                            'is] good and in the Hereafter [that which is] '
                            'good and protect us from the punishment of the '
                            'Fire."',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Surah Al-Baqarah (2:201)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _FavoriteRow extends StatelessWidget {
  final FavoriteDua item;
  const _FavoriteRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => UiActions.addFavoriteDua(
          context,
          title: item.title,
          subtitle: item.subtitle,
        ),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            letterSpacing: 0.65,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
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
/// Right column: category grid
/// ---------------------------------------------------------------------
class _CategoriesColumn extends StatelessWidget {
  final List<DuaCategory> categories;
  const _CategoriesColumn({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Categories',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
          children: [
            for (final category in categories)
              _CategoryTile(category: category),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final DuaCategory category;
  const _CategoryTile({required this.category});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovering = false;

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
          onTap: () => UiActions.openSearch(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
            child: GlassSurface(
              borderRadius: BorderRadius.circular(12),
              tint: _hovering
                  ? AppColors.surfaceVariant.withOpacity(0.4)
                  : const Color(0x992F3632),
              border: Border.all(
                color: _hovering
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _hovering ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Icon(
                          widget.category.icon,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.category.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        letterSpacing: 0.65,
                        color: _hovering
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _BottomNavBar and _NavItem → replaced by SharedBottomNavBar from app_theme_tokens.dart
