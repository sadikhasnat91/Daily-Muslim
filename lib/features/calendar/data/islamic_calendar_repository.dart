import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:islam/core/network/api_client.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';

final islamicCalendarRepositoryProvider = Provider<IslamicCalendarRepository>((_) {
  return IslamicCalendarRepository(HiveService.instance);
});

class CalendarDayData {
  const CalendarDayData({
    required this.gregorianDate,
    required this.hijriDateLabel,
    required this.hijriDay,
    required this.hijriMonthNumber,
    required this.hijriYear,
    required this.weekday,
    required this.events,
  });

  final DateTime gregorianDate;
  final String hijriDateLabel;
  final int hijriDay;
  final int hijriMonthNumber;
  final int hijriYear;
  final String weekday;
  final List<IslamicEventData> events;
}

class IslamicEventData {
  const IslamicEventData({
    required this.name,
    required this.hijriMonth,
    required this.hijriDay,
    required this.description,
  });

  final String name;
  final int hijriMonth;
  final int hijriDay;
  final String description;
}

class IslamicCalendarRepository {
  IslamicCalendarRepository(this._hive);

  final HiveService _hive;

  static const _events = <IslamicEventData>[
    IslamicEventData(
      name: 'Islamic New Year',
      hijriMonth: 1,
      hijriDay: 1,
      description: 'The first day of Muharram and the beginning of a new Hijri year.',
    ),
    IslamicEventData(
      name: 'Ashura',
      hijriMonth: 1,
      hijriDay: 10,
      description: 'A significant day of fasting and remembrance observed on the 10th of Muharram.',
    ),
    IslamicEventData(
      name: 'Mawlid',
      hijriMonth: 3,
      hijriDay: 12,
      description: 'The birth anniversary of Prophet Muhammad (peace be upon him).',
    ),
    IslamicEventData(
      name: 'Isra and Mi\'raj',
      hijriMonth: 7,
      hijriDay: 27,
      description: 'Commemorates the Night Journey and Ascension of the Prophet (peace be upon him).',
    ),
    IslamicEventData(
      name: 'Shab-e-Barat',
      hijriMonth: 8,
      hijriDay: 15,
      description: 'The mid-Sha\'ban night widely observed with prayer and reflection.',
    ),
    IslamicEventData(
      name: 'Ramadan Begins',
      hijriMonth: 9,
      hijriDay: 1,
      description: 'The first day of the blessed month of Ramadan.',
    ),
    IslamicEventData(
      name: 'Laylatul Qadr',
      hijriMonth: 9,
      hijriDay: 27,
      description: 'A highly blessed night in the last ten nights of Ramadan.',
    ),
    IslamicEventData(
      name: 'Eid-ul-Fitr',
      hijriMonth: 10,
      hijriDay: 1,
      description: 'Festival marking the end of Ramadan.',
    ),
    IslamicEventData(
      name: 'Day of Arafah',
      hijriMonth: 12,
      hijriDay: 9,
      description: 'A sacred day during Hajj observed with fasting by many Muslims.',
    ),
    IslamicEventData(
      name: 'Eid-ul-Adha',
      hijriMonth: 12,
      hijriDay: 10,
      description: 'Festival of sacrifice commemorating the devotion of Prophet Ibrahim (peace be upon him).',
    ),
  ];

  Future<List<CalendarDayData>> loadMonth({
    required int year,
    required int month,
  }) async {
    final settings =
        _hive.settingsBox.get(HiveKeys.appSettings) as Map<dynamic, dynamic>?;
    final city = (settings?['city'] as String?) ?? 'Makkah';
    final country = (settings?['country'] as String?) ?? 'Saudi Arabia';
    final method = (settings?['prayerMethod'] as int?) ?? 4;

    final cacheKey = 'calendar_${year}_${month}_${city}_${country}_$method';
    final api = ApiClient();
    final response = await api.get(
      'https://api.aladhan.com/v1/calendarByCity/$year/$month',
      query: {
        'city': city,
        'country': country,
        'method': method,
        'month': month,
        'year': year,
      },
      timeout: const Duration(seconds: 16),
    );

    if (response.isSuccess) {
      final raw = response.data?['data'];
      if (raw is List) {
        final parsed = raw.whereType<Map>().map(_parseCalendarDay).toList(growable: false);
        if (parsed.isNotEmpty) {
          await _hive.settingsBox.put(
            cacheKey,
            parsed
                .map(
                  (day) => {
                    'gregorianDate': day.gregorianDate.toIso8601String(),
                    'hijriDateLabel': day.hijriDateLabel,
                    'hijriDay': day.hijriDay,
                    'hijriMonthNumber': day.hijriMonthNumber,
                    'hijriYear': day.hijriYear,
                    'weekday': day.weekday,
                    'events': day.events
                        .map(
                          (event) => {
                            'name': event.name,
                            'hijriMonth': event.hijriMonth,
                            'hijriDay': event.hijriDay,
                            'description': event.description,
                          },
                        )
                        .toList(growable: false),
                  },
                )
                .toList(growable: false),
          );
          return parsed;
        }
      }
    }

    final cached = _hive.settingsBox.get(cacheKey);
    if (cached is List) {
      return cached.whereType<Map>().map((item) {
        final rawEvents = (item['events'] as List?) ?? const [];
        return CalendarDayData(
          gregorianDate: DateTime.tryParse((item['gregorianDate'] as String?) ?? '') ??
              DateTime(year, month, 1),
          hijriDateLabel: (item['hijriDateLabel'] as String?) ?? '',
          hijriDay: (item['hijriDay'] as num?)?.toInt() ?? 1,
          hijriMonthNumber: (item['hijriMonthNumber'] as num?)?.toInt() ?? 1,
          hijriYear: (item['hijriYear'] as num?)?.toInt() ?? 1448,
          weekday: (item['weekday'] as String?) ?? '',
          events: rawEvents.whereType<Map>().map((event) {
            return IslamicEventData(
              name: (event['name'] as String?) ?? '',
              hijriMonth: (event['hijriMonth'] as num?)?.toInt() ?? 1,
              hijriDay: (event['hijriDay'] as num?)?.toInt() ?? 1,
              description: (event['description'] as String?) ?? '',
            );
          }).toList(growable: false),
        );
      }).toList(growable: false);
    }

    return const [];
  }

  CalendarDayData _parseCalendarDay(Map raw) {
    final date = raw['date'] as Map? ?? const {};
    final gregorian = date['gregorian'] as Map? ?? const {};
    final hijri = date['hijri'] as Map? ?? const {};
    final day = int.tryParse((gregorian['day'] as String?) ?? '') ?? 1;
    final month = ((gregorian['month'] as Map?)?['number'] as num?)?.toInt() ?? 1;
    final year = int.tryParse((gregorian['year'] as String?) ?? '') ?? 2026;
    final hijriDay = int.tryParse((hijri['day'] as String?) ?? '') ?? 1;
    final hijriMonth = ((hijri['month'] as Map?)?['number'] as num?)?.toInt() ?? 1;
    final hijriYear = int.tryParse((hijri['year'] as String?) ?? '') ?? 1448;
    final hijriMonthName = ((hijri['month'] as Map?)?['en'] as String?) ?? '';
    final events = _events
        .where((event) => event.hijriMonth == hijriMonth && event.hijriDay == hijriDay)
        .toList(growable: false);

    return CalendarDayData(
      gregorianDate: DateTime(year, month, day),
      hijriDateLabel: '$hijriDay $hijriMonthName $hijriYear AH',
      hijriDay: hijriDay,
      hijriMonthNumber: hijriMonth,
      hijriYear: hijriYear,
      weekday: ((gregorian['weekday'] as Map?)?['en'] as String?) ??
          DateFormat('EEEE').format(DateTime(year, month, day)),
      events: events,
    );
  }
}
