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
    List<String>? reminderTimes,
    String? categoryLabel,
    int? categoryColor,
    int? categoryIconCodePoint,
    String? frequencyLabel,
  });
  Future<void> updateHabit({
    required String habitId,
    String? name,
    String? haId,
    bool setHaId = false,
    int? order,
    bool setOrder = false,
    String? description,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool setEndDate = false,
    int? reminderCount,
    List<String>? reminderTimes,
    bool setReminderTimes = false,
    String? categoryLabel,
    int? categoryColor,
    int? categoryIconCodePoint,
    String? frequencyLabel,
    bool? active,
  });
  Future<void> deleteHabit(String habitId);
  Future<void> resetHabitProgress(String habitId);
  Future<void> deleteAllHabitsAndCompletions();
  Future<void> seedHabitsIfEmpty();
}
