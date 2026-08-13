import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_service.dart';

final duaRepositoryProvider = Provider<DuaRepository>((_) {
  return DuaRepository(HiveService.instance);
});

class DuaRepository {
  DuaRepository(this._hive);

  final HiveService _hive;

  final categories = const [
    'Morning / Evening',
    'Sleep',
    'Travel',
    'Forgiveness',
    'Health',
    'Success',
  ];

  Future<void> addFavorite(String key, Map<String, dynamic> value) async {
    await _hive.favoritesBox.put(key, value);
  }

  List<Map<dynamic, dynamic>> getFavorites() {
    return _hive.favoritesBox.values.whereType<Map<dynamic, dynamic>>().toList(
      growable: false,
    );
  }
}
