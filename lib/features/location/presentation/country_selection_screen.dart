import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text('Select Country')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search country, capital, or timezone',
                  ),
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: countriesAsync.when(
                    data: (countries) {
                      final visible = repository.search(countries, _query);
                      if (visible.isEmpty) {
                        return const Center(child: Text('No countries found'));
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final country = visible[index];
                                return Card(
                                  child: ListTile(
                                    leading: Text(
                                      country.flagEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    title: Text(country.name),
                                    subtitle: Text(
                                      '${country.capital} • ${country.timezoneDisplay}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.of(context).pop(country),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Country/timezone data: Countries States Cities Database',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                    error: (error, _) => Center(
                      child: Text(
                        'Unable to load countries right now.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
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
