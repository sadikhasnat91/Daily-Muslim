class CountryOption {
  const CountryOption({
    required this.name,
    required this.isoCode,
    required this.flagEmoji,
    required this.capital,
    required this.timezoneId,
    required this.utcOffsetLabel,
    this.latitude = 0,
    this.longitude = 0,
  });

  final String name;
  final String isoCode;
  final String flagEmoji;
  final String capital;
  final String timezoneId;
  final String utcOffsetLabel;
  final double latitude;
  final double longitude;

  String get timezoneDisplay => '$timezoneId ($utcOffsetLabel)';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isoCode': isoCode,
      'flagEmoji': flagEmoji,
      'capital': capital,
      'timezoneId': timezoneId,
      'utcOffsetLabel': utcOffsetLabel,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CountryOption.fromJson(Map<dynamic, dynamic> json) {
    String timezoneId = 'UTC';
    String utcOffsetLabel = 'UTC+00:00';

    final timezones = json['timezones'];
    if (timezones is List && timezones.isNotEmpty) {
      final first = timezones.first;
      if (first is Map) {
        timezoneId = (first['zoneName'] as String?) ?? timezoneId;
        utcOffsetLabel = (first['gmtOffsetName'] as String?) ?? utcOffsetLabel;
      } else if (first is String) {
        timezoneId = first;
      }
    } else {
      timezoneId = (json['timezoneId'] as String?) ?? timezoneId;
      utcOffsetLabel = (json['utcOffsetLabel'] as String?) ?? utcOffsetLabel;
    }

    final latitude =
        ((json['latitude'] ?? json['lat']) as num?)?.toDouble() ?? 0;
    final longitude =
        ((json['longitude'] ?? json['lng'] ?? json['lon']) as num?)
            ?.toDouble() ??
        0;

    return CountryOption(
      name: (json['name'] as String?) ?? 'Unknown',
      isoCode: ((json['iso2'] ?? json['isoCode']) as String? ?? 'XX')
          .toUpperCase(),
      flagEmoji:
          (json['emoji'] as String?) ??
          (json['flagEmoji'] as String?) ??
          _flagEmojiForIsoCode(
            ((json['iso2'] ?? json['isoCode']) as String?) ?? 'XX',
          ),
      capital:
          (json['capital'] as String?) ??
          (json['name'] as String?) ??
          'Unknown',
      timezoneId: timezoneId,
      utcOffsetLabel: utcOffsetLabel,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String flagFromCode(String isoCode) => _flagEmojiForIsoCode(isoCode);
}

String _flagEmojiForIsoCode(String isoCode) {
  final code = isoCode.trim().toUpperCase();
  if (code.length != 2) {
    return '🏳';
  }
  final chars = code.codeUnits.map(
    (unit) => String.fromCharCode(unit + 127397),
  );
  return chars.join();
}
