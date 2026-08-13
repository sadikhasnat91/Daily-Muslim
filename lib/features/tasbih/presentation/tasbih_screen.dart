import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islam/features/tasbih/presentation/tasbih_controller.dart';

class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tasbihControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(tasbihControllerProvider.notifier).increment();
              },
              child: const Text('Count'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(tasbihControllerProvider.notifier).reset();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
