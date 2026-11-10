// country_selection_screen.dart
//
// Muslim Daily – World-Class 3D Country & Timezone Selection Screen.
// Fast searchable database of world nations, flags, capitals, and timezones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/data/country_repository.dart';
import 'package:islam/features/location/domain/country_option.dart';

final countryCatalogProvider = FutureProvider<List<CountryOption>>((ref) async {
  final repository = ref.watch(countryRepositoryProvider);
  return repository.loadCountries();
});

class CountrySelectionScreen extends ConsumerStatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  ConsumerState<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends ConsumerState<CountrySelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(countryCatalogProvider);
    final repository = ref.watch(countryRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Select Country',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: 20,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 240, opacity: 0.12),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 220, opacity: 0.08),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      // 3D Search Field
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
                          controller: _searchController,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.onBackground),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            hintText: 'Search country, capital, or timezone...',
                            filled: true,
                            fillColor: AppColors.surfaceContainer.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _query = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Countries List
                      Expanded(
                        child: countriesAsync.when(
                          data: (countries) {
                            final visible = repository.search(countries, _query);
                            if (visible.isEmpty) {
                              return Center(
                                child: Text(
                                  'No countries found matching "$_query"',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final country = visible[index];
                                return ScaleButton(
                                  onTap: () => Navigator.of(context).pop(country),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
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
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.surfaceVariant.withOpacity(0.5),
                                          ),
                                          child: Text(
                                            country.flagEmoji,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                country.name,
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
                                                '${country.capital} • ${country.timezoneDisplay}',
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
                              },
                            );
                          },
                          error: (error, _) => Center(
                            child: Text(
                              'Unable to load countries.\n$error',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
