import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/day_chip.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/presentation/providers/today_completions_provider.dart';
import 'package:ritual/features/habits/presentation/providers/today_selected_date_provider.dart';
import 'package:ritual/habit_row.dart';
import 'package:ritual/habit_ui_model.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(todaySelectedDateProvider);
    final dateKey = dateKeyFromDateTime(selectedDate);
    ref.watch(todayCompletionsProvider);
    final completionsNotifier =
        ref.read(todayCompletionsProvider.notifier);
    final days = _buildDays();

    const habits = [
      HabitUIModel(
        id: 'agua_despertar',
        title: 'Agua al despertar',
        color: Color(0xFFF4B23C),
        icon: Icons.local_drink,
        tagText: 'Hábito | 6p',
      ),
      HabitUIModel(
        id: 'cepillar_desayuno',
        title: 'Cepillarme los dientes antes de desayunar',
        color: Color(0xFF7FC34A),
        icon: Icons.add,
        tagText: 'Hábito | 6p',
      ),
      HabitUIModel(
        id: 'skin_am',
        title: 'Rutina de piel por la mañana',
        color: Color(0xFF7FC34A),
        icon: Icons.add,
        tagText: 'Hábito | 6p',
      ),
      HabitUIModel(
        id: 'desayunar',
        title: 'Desayunar lo primero (no recoger nada antes)',
        color: Color(0xFFE24B3C),
        icon: Icons.block,
        tagText: 'Hábito | 5p',
      ),
      HabitUIModel(
        id: 'suplementos_am',
        title: 'Suplementos de la mañana',
        color: Color(0xFFD44BC4),
        icon: Icons.self_improvement,
        tagText: 'Hábito | 4p',
      ),
      HabitUIModel(
        id: 'skin_pm',
        title: 'Rutina de piel por la noche',
        color: Color(0xFF7FC34A),
        icon: Icons.add,
        tagText: 'Hábito | 3p',
      ),
      HabitUIModel(
        id: 'suplementos_pm',
        title: 'Suplementos de la noche',
        color: Color(0xFFF4B23C),
        icon: Icons.local_drink,
        tagText: 'Hábito | 3p',
      ),
      HabitUIModel(
        id: 'cepillar_dormir',
        title: 'Cepillarme los dientes antes de dormir',
        color: Color(0xFF7FC34A),
        icon: Icons.add,
        tagText: 'Hábito | 2p',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'Hoy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final item = days[index];
                final isSelected = _isSameDay(item.date, selectedDate);
                return DayChip(
                  dayLabel: item.label,
                  dayNumber: item.number,
                  isSelected: isSelected,
                  isToday: _isSameDay(item.date, DateTime.now()),
                  onTap: () => ref
                      .read(todaySelectedDateProvider.notifier)
                      .state = item.date,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: habits.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isDone =
                    completionsNotifier.isCompleted(dateKey, habit.id);
                return HabitRow(
                  habit: habit,
                  isDone: isDone,
                  onToggle: () => ref
                      .read(todayCompletionsProvider.notifier)
                      .toggleCompletion(dateKey, habit.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayItem {
  final DateTime date;
  final String label;
  final String number;

  const _DayItem(this.date, this.label, this.number);
}

List<_DayItem> _buildDays() {
  final today = DateTime.now();
  final base = DateTime(today.year, today.month, today.day);
  final days = <_DayItem>[];
  for (var i = -4; i <= 4; i++) {
    final date = base.add(Duration(days: i));
    days.add(_DayItem(date, _weekdayLabel(date.weekday), '${date.day}'));
  }
  return days;
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Lun';
    case DateTime.tuesday:
      return 'Mar';
    case DateTime.wednesday:
      return 'Mié';
    case DateTime.thursday:
      return 'Jue';
    case DateTime.friday:
      return 'Vie';
    case DateTime.saturday:
      return 'Sáb';
    case DateTime.sunday:
      return 'Dom';
    default:
      return '';
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
