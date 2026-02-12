import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';
import 'package:ritual/features/habits/presentation/widgets/habit_card.dart';
import 'package:ritual/features/habits/presentation/widgets/week_dots.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(watchActiveHabitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hábitos')),
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
              final completions = ref.watch(habitWeekCompletionsProvider(habit.id));
              return HabitCard(
                habit: habit,
                onTap: () => context.push('/habit/${habit.id}'),
                trailing: completions.when(
                  data: (list) => SizedBox(
                    width: 80,
                    child: WeekDots(
                      completions: list,
                      color: Color(habit.color),
                    ),
                  ),
                  loading: () => const SizedBox(width: 80, child: LinearProgressIndicator()),
                  error: (err, _) => const SizedBox(width: 80, child: Icon(Icons.error)),
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
