import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/storage/hive_keys.dart';
import 'package:islam/core/storage/hive_service.dart';

final tasbihControllerProvider = NotifierProvider<TasbihController, int>(
  TasbihController.new,
);

class TasbihController extends Notifier<int> {
  @override
  int build() {
    return (HiveService.instance.tasbihBox.get(HiveKeys.tasbihCounter)
            as int?) ??
        0;
  }

  Future<void> increment() async {
    state += 1;
    await HiveService.instance.tasbihBox.put(HiveKeys.tasbihCounter, state);
  }

  Future<void> reset() async {
    state = 0;
    await HiveService.instance.tasbihBox.put(HiveKeys.tasbihCounter, state);
  }
}
