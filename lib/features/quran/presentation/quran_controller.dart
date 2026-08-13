import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/features/quran/data/quran_repository.dart';
import 'package:islam/features/quran/domain/surah.dart';

final quranSearchQueryProvider = StateProvider<String>((_) => '');

final quranSearchResultsProvider = Provider<List<Surah>>((ref) {
  final query = ref.watch(quranSearchQueryProvider);
  final repo = ref.watch(quranRepositoryProvider);
  return repo.search(query);
});
