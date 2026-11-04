import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/core/navigation/ui_actions.dart';
import 'package:islam/features/quran/presentation/quran_controller.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(quranSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search Surah by name, number, or Arabic text',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    ref.read(quranSearchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('No results found'))
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(item.subtitle),
                                trailing: Text(item.arabic),
                                onTap: () => UiActions.openQuranReader(
                                  context,
                                  surahId: item.id,
                                ),
                              ),
                            );
                          },
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
