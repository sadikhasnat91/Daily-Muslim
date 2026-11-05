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

    double parseCoordinate(dynamic raw) {
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? 0.0;
      return 0.0;
    }

    var latitude = parseCoordinate(json['latitude'] ?? json['lat']);
    var longitude = parseCoordinate(json['longitude'] ?? json['lng'] ?? json['lon']);

    final isoCode = ((json['iso2'] ?? json['isoCode']) as String? ?? 'XX')
        .toUpperCase();
    final countryName = (json['name'] as String?) ?? 'Unknown';

    if ((latitude == 0.0 && longitude == 0.0) ||
        (isoCode == 'BD' || countryName.toLowerCase() == 'bangladesh')) {
      if (isoCode == 'BD' || countryName.toLowerCase() == 'bangladesh') {
        latitude = 23.8103;
        longitude = 90.4125;
      }
    }

    return CountryOption(
      name: countryName,
      isoCode: isoCode,
      flagEmoji:
          (json['emoji'] as String?) ??
          (json['flagEmoji'] as String?) ??
          _flagEmojiForIsoCode(isoCode),
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
