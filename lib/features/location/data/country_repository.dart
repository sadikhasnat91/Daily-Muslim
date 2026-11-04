import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_service.dart';
import 'package:islam/features/location/domain/country_option.dart';

final countryRepositoryProvider = Provider<CountryRepository>((_) {
  return CountryRepository(HiveService.instance);
});

class CountryRepository {
  CountryRepository(this._hive);

  final HiveService _hive;
  final Dio _dio = Dio();

  static const _cacheKey = 'country_catalog_cache_v1';
  static const _sourceUrl =
      'https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/countries.json';

  Future<List<CountryOption>> loadCountries() async {
    final cached = _readCache();
    try {
      final response = await _dio
          .get<List<dynamic>>(
            _sourceUrl,
            options: Options(responseType: ResponseType.json),
          )
          .timeout(const Duration(seconds: 20));
      final data = response.data;
      if (data != null) {
        final countries =
            data
                .whereType<Map>()
                .map(CountryOption.fromJson)
                .where((country) => country.name.trim().isNotEmpty)
                .toList(growable: false)
              ..sort((a, b) => a.name.compareTo(b.name));
        if (countries.isNotEmpty) {
          await _hive.settingsBox.put(
            _cacheKey,
            countries
                .map((country) => country.toJson())
                .toList(growable: false),
          );
          return countries;
        }
      }
    } catch (_) {
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    if (cached.isNotEmpty) {
      return cached;
    }
    return _fallbackCountries;
  }

  List<CountryOption> search(List<CountryOption> countries, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return countries;
    }
    return countries
        .where((country) {
          return country.name.toLowerCase().contains(normalized) ||
              country.capital.toLowerCase().contains(normalized) ||
              country.timezoneId.toLowerCase().contains(normalized) ||
              country.isoCode.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  List<CountryOption> _readCache() {
    final cached = _hive.settingsBox.get(_cacheKey);
    if (cached is! List) {
      return const [];
    }
    return cached
        .whereType<Map>()
        .map(CountryOption.fromJson)
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

const _fallbackCountries = <CountryOption>[
  CountryOption(
    name: 'Bangladesh',
    isoCode: 'BD',
    flagEmoji: '🇧🇩',
    capital: 'Dhaka',
    timezoneId: 'Asia/Dhaka',
    utcOffsetLabel: 'UTC+06:00',
    latitude: 23.8103,
    longitude: 90.4125,
  ),
  CountryOption(
    name: 'India',
    isoCode: 'IN',
    flagEmoji: '🇮🇳',
    capital: 'New Delhi',
    timezoneId: 'Asia/Kolkata',
    utcOffsetLabel: 'UTC+05:30',
    latitude: 28.6139,
    longitude: 77.2090,
  ),
  CountryOption(
    name: 'Pakistan',
    isoCode: 'PK',
    flagEmoji: '🇵🇰',
    capital: 'Islamabad',
    timezoneId: 'Asia/Karachi',
    utcOffsetLabel: 'UTC+05:00',
    latitude: 33.6844,
    longitude: 73.0479,
  ),
  CountryOption(
    name: 'Saudi Arabia',
    isoCode: 'SA',
    flagEmoji: '🇸🇦',
    capital: 'Makkah',
    timezoneId: 'Asia/Riyadh',
    utcOffsetLabel: 'UTC+03:00',
    latitude: 21.4225,
    longitude: 39.8262,
  ),
  CountryOption(
    name: 'United Arab Emirates',
    isoCode: 'AE',
    flagEmoji: '🇦🇪',
    capital: 'Abu Dhabi',
    timezoneId: 'Asia/Dubai',
    utcOffsetLabel: 'UTC+04:00',
    latitude: 24.4539,
    longitude: 54.3773,
  ),
];
