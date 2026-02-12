import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';

abstract class HabitsRepository {
  Stream<List<Habit>> watchActiveHabits();
  Stream<Map<String, Completion>> watchCompletionsForDate(String dateKey);
  Stream<List<Completion>> watchCompletionsRange(
    String habitId,
    String fromDateKey,
    String toDateKey,
  );
  Future<void> markDone(String habitId, String dateKey, {String source});
  Future<void> unmarkDone(String habitId, String dateKey);
  Future<void> createHabit({
    required String name,
    required String icon,
    required int color,
    String? description,
    String? haId,
    bool active = true,
    int? order,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? reminderCount,
  });
  Future<void> deleteAllHabitsAndCompletions();
  Future<void> seedHabitsIfEmpty();
}
