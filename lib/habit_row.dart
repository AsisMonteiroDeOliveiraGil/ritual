import 'package:flutter/material.dart';
import 'package:ritual/habit_ui_model.dart';

class HabitRow extends StatelessWidget {
  final HabitUIModel habit;
  final bool isDone;
  final VoidCallback onToggle;

  const HabitRow({
    super.key,
    required this.habit,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: habit.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(habit.icon, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      habit.tagText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DoneIndicator(isDone: isDone),
          ],
        ),
      ),
    );
  }
}

class _DoneIndicator extends StatelessWidget {
  final bool isDone;

  const _DoneIndicator({required this.isDone});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? accent : Colors.transparent,
        border: Border.all(
          color: isDone ? accent : Colors.white24,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isDone
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}
