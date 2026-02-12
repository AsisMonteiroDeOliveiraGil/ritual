import 'package:flutter/material.dart';
import 'package:ritual/core/ui/icon_mapper.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(iconFromName(habit.icon), color: color),
        ),
        title: Text(habit.name),
        trailing: trailing,
      ),
    );
  }
}
