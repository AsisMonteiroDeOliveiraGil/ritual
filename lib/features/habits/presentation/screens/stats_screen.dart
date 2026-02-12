import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(watchActiveHabitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: habits.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No hay hábitos activos.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final habit = items[index];
              final stats = ref.watch(habitStatsProvider(habit.id));
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: stats.when(
                    data: (s) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('7 días: ${(s.percent7 * 100).round()}%'),
                        Text('30 días: ${(s.percent30 * 100).round()}%'),
                        Text('90 días: ${(s.percent90 * 100).round()}%'),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
