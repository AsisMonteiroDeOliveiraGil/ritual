import 'package:flutter/material.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';

class WeekDots extends StatelessWidget {
  final List<Completion> completions;
  final Color color;

  const WeekDots({super.key, required this.completions, required this.color});

  @override
  Widget build(BuildContext context) {
    final keys = dateKeysForLastNDays(7);
    final set = completions.map((c) => c.dateKey).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        final done = set.contains(key);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: done ? color : color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
