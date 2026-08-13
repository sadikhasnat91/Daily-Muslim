import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/features/prayer/presentation/prayer_controller.dart';

class PrayerTrackerScreen extends ConsumerWidget {
  const PrayerTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prayerTrackerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Tracker')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final prayer in state.keys)
                CheckboxListTile(
                  title: Text(prayer),
                  value: state[prayer],
                  onChanged: (_) {
                    ref.read(prayerTrackerProvider.notifier).toggle(prayer);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
