class Surah {
  const Surah({
    required this.id,
    required this.name,
    required this.arabic,
    required this.verses,
    required this.place,
  });

  final int id;
  final String name;
  final String arabic;
  final int verses;
  final String place;

  String get subtitle => '$place • $verses verses';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arabic': arabic,
      'verses': verses,
      'place': place,
    };
  }

  factory Surah.fromJson(Map<dynamic, dynamic> json) {
    return Surah(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Unknown',
      arabic: (json['arabic'] as String?) ?? 'Unknown',
      verses: (json['verses'] as num?)?.toInt() ?? 0,
      place: (json['place'] as String?) ?? 'Unknown',
    );
  }
}
