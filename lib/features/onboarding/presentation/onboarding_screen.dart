import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam/app/app_routes.dart';
import 'package:islam/core/ui/app_theme_tokens.dart';
import 'package:islam/features/location/domain/country_option.dart';
import 'package:islam/features/settings/presentation/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late String _selectedCountry;
  late String _selectedCountryCode;
  late String _selectedTimezone;
  late String _selectedCity;
  double _selectedLatitude = 23.8103;
  double _selectedLongitude = 90.4125;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    _nameController.text = settings.profileName;
    _emailController.text = settings.profileEmail;
    _selectedCountry = settings.country;
    _selectedCountryCode = settings.countryCode;
    _selectedTimezone = settings.timezone;
    _selectedCity = settings.city;
    _selectedLatitude = settings.latitude == 0.0 ? 23.8103 : settings.latitude;
    _selectedLongitude = settings.longitude == 0.0 ? 90.4125 : settings.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _saving = true);
    final notifier = ref.read(settingsControllerProvider.notifier);

    await notifier.setProfileName(
      _nameController.text.trim().isEmpty
          ? 'Muslim Daily User'
          : _nameController.text.trim(),
    );
    await notifier.setProfileEmail(_emailController.text.trim());
    await notifier.applyCountry(
      CountryOption(
        name: _selectedCountry,
        isoCode: _selectedCountryCode,
        flagEmoji: CountryOption.flagFromCode(_selectedCountryCode),
        capital: _selectedCity,
        timezoneId: _selectedTimezone,
        utcOffsetLabel: 'Auto',
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      ),
    );
    await notifier.setOnboardingComplete(true);

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -60,
            right: -60,
            child: GlowOrb(color: AppColors.primary, radius: 220, opacity: 0.16),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: GlowOrb(color: AppColors.gold, radius: 240, opacity: 0.1),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // 3D Floating Icon Header
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1F3D2E), Color(0xFF102018)],
                            ),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: -2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 10),
                                blurRadius: 20,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.15),
                                offset: const Offset(0, -1),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Welcome Texts
                      Text(
                        'Welcome to Daily Muslim',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Personalize your spiritual journey with precise prayer times and Quran recitations.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 3D Glass Form Card
                      Card3D(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROFILE DETAILS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name field
                            TextField(
                              controller: _nameController,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Email field
                            TextField(
                              controller: _emailController,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.onBackground,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email (Optional)',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              'LOCATION & TIMEZONE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 3D Country Picker Tile
                            ScaleButton(
                              onTap: () async {
                                final selected = await context.push<CountryOption>(
                                  AppRoutes.countrySelection,
                                );
                                if (selected == null || !mounted) return;
                                var lat = selected.latitude;
                                var lng = selected.longitude;
                                if ((lat == 0.0 && lng == 0.0) ||
                                    selected.isoCode == 'BD' ||
                                    selected.name.toLowerCase() == 'bangladesh') {
                                  final resolved = SettingsController.resolveCoordinates(
                                          selected.capital, selected.name) ??
                                      (23.8103, 90.4125);
                                  lat = resolved.$1;
                                  lng = resolved.$2;
                                }
                                setState(() {
                                  _selectedCountry = selected.name;
                                  _selectedCountryCode = selected.isoCode;
                                  _selectedTimezone = selected.timezoneId;
                                  _selectedCity = selected.capital;
                                  _selectedLatitude = lat;
                                  _selectedLongitude = lng;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        CountryOption.flagFromCode(_selectedCountryCode),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_selectedCountry, $_selectedCity',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onBackground,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedTimezone,
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
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 3D Get Started Button
                      Button3D(
                        label: _saving ? 'Setting Up...' : 'Get Started',
                        icon: _saving ? null : Icons.arrow_forward_rounded,
                        isFullWidth: true,
                        onTap: _saving ? null : _completeOnboarding,
                        glowColor: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
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
