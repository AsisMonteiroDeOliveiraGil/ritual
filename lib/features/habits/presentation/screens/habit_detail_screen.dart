import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/core/ui/icon_mapper.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/entities/habit_stats.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(watchActiveHabitsProvider);
    final stats = ref.watch(habitStatsProvider(habitId));

    Habit? habit;
    habits.whenData((items) {
      for (final h in items) {
        if (h.id == habitId) {
          habit = h;
          break;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          habits.when(
            data: (_) {
              if (habit == null) {
                return const Text('Hábito no encontrado.');
              }
              final color = Color(habit!.color);
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(iconFromName(habit!.icon), color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(habit!.name, style: Theme.of(context).textTheme.titleLarge),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
          const SizedBox(height: 16),
          stats.when(
            data: (s) => _StatsContent(stats: s),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final HabitStats stats;

  const _StatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatTile(label: 'Racha actual', value: stats.currentStreak.toString()),
            const SizedBox(width: 12),
            _StatTile(label: 'Racha máx', value: stats.maxStreak.toString()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(label: '7 días', value: _percent(stats.percent7)),
            const SizedBox(width: 12),
            _StatTile(label: '30 días', value: _percent(stats.percent30)),
            const SizedBox(width: 12),
            _StatTile(label: '90 días', value: _percent(stats.percent90)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  spots: _toSpots(stats.last30Days),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _percent(double value) => '${(value * 100).round()}%';

  List<FlSpot> _toSpots(List<int> values) {
    return List.generate(values.length, (index) {
      return FlSpot(index.toDouble(), values[index].toDouble());
    });
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
