import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageBg = Color(0xFF0B0D11);
    const cardBg = Color(0xFF191C21);
    final habits = ref.watch(watchActiveHabitsProvider);
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: habits.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No hay hábitos activos.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final sorted = [...items]..sort((a, b) => a.order.compareTo(b.order));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HabitDotsMatrix(habits: sorted, cardBg: cardBg),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _HabitDotsMatrix extends ConsumerWidget {
  final List<Habit> habits;
  final Color cardBg;

  const _HabitDotsMatrix({required this.habits, required this.cardBg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = logicalDateFromDateTime(DateTime.now());
    DateTime? oldestStart;
    for (final habit in habits) {
      final start = habit.startDate;
      if (start == null) continue;
      final normalized = DateTime(start.year, start.month, start.day);
      if (oldestStart == null || normalized.isBefore(oldestStart)) {
        oldestStart = normalized;
      }
    }
    final startDate = oldestStart ??
        DateTime(today.year, today.month, today.day).subtract(
          const Duration(days: 29),
        );
    final totalDays = today.difference(startDate).inDays + 1;
    final dates = List<DateTime>.generate(
      totalDays,
      (i) => DateTime(startDate.year, startDate.month, startDate.day).add(
        Duration(days: i),
      ),
    );
    final keys = dates.map(dateKeyFromDateTime).toList();

    final dayStates = {
      for (final key in keys) key: ref.watch(completionsForDateProvider(key)),
    };
    final hasError = dayStates.values.any((value) => value.hasError);
    final isLoading = dayStates.values.any((value) => value.isLoading);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mapa de hábitos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filas: hábitos · Columnas: días (desde ${startDate.day}/${startDate.month}/${startDate.year})',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (hasError)
            const Text(
              'No se pudo cargar el mapa.',
              style: TextStyle(color: Colors.white70),
            )
          else if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 2),
              child: _DotsGridTable(
                habits: habits,
                keys: keys,
                dates: dates,
                dayCompletions: {
                  for (final entry in dayStates.entries)
                    entry.key: entry.value.asData?.value ?? const {},
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DotsGridTable extends StatelessWidget {
  final List<Habit> habits;
  final List<String> keys;
  final List<DateTime> dates;
  final Map<String, Map<String, dynamic>> dayCompletions;

  const _DotsGridTable({
    required this.habits,
    required this.keys,
    required this.dates,
    required this.dayCompletions,
  });

  @override
  Widget build(BuildContext context) {
    const nameWidth = 172.0;
    const dotSize = 11.0;
    const gap = 5.0;

    final tableWidth = nameWidth + ((dotSize + gap) * keys.length);

    return SizedBox(
      width: tableWidth,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: nameWidth,
                child: Text(
                  'Hábito',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...List.generate(keys.length, (index) {
                final show = index % 5 == 0 || index == keys.length - 1;
                return SizedBox(
                  width: dotSize + gap,
                  child: Text(
                    show ? '${dates[index].day}' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          ...habits.map((habit) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: nameWidth,
                    child: Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ...keys.map((key) {
                    final start = habit.startDate;
                    final startKey = start == null
                        ? null
                        : dateKeyFromDateTime(
                            DateTime(start.year, start.month, start.day),
                          );
                    if (startKey != null && key.compareTo(startKey) < 0) {
                      return const SizedBox(
                        width: dotSize + gap,
                        height: dotSize,
                      );
                    }
                    final done = dayCompletions[key]?.containsKey(habit.id) ?? false;
                    return Container(
                      width: dotSize,
                      height: dotSize,
                      margin: const EdgeInsets.only(right: gap),
                      decoration: BoxDecoration(
                        color: done ? const Color(0xFF00C565) : const Color(0xFFFF3366),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
