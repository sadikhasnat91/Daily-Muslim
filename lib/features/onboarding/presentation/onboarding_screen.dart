import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islam/app/app_routes.dart';
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
      ),
    );
    await notifier.setOnboardingComplete(true);

    if (!mounted) {
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to Muslim Daily',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your profile and location to personalize prayer times.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Country'),
                    subtitle: Text(
                      '${CountryOption.flagFromCode(_selectedCountryCode)} $_selectedCountry\n$_selectedTimezone',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await context.push<CountryOption>(
                        AppRoutes.countrySelection,
                      );
                      if (selected == null || !mounted) {
                        return;
                      }
                      setState(() {
                        _selectedCountry = selected.name;
                        _selectedCountryCode = selected.isoCode;
                        _selectedTimezone = selected.timezoneId;
                        _selectedCity = selected.capital;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Timezone'),
                    subtitle: Text(_selectedTimezone),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _completeOnboarding,
                      child: Text(_saving ? 'Saving...' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
