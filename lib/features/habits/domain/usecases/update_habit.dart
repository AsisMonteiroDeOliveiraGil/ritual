import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class UpdateHabit {
  final HabitsRepository _repository;

  UpdateHabit(this._repository);

  Future<void> call({
    required String habitId,
    String? name,
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
  }) {
    return _repository.updateHabit(
      habitId: habitId,
      name: name,
      description: description,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      setEndDate: setEndDate,
      reminderCount: reminderCount,
      reminderTimes: reminderTimes,
      setReminderTimes: setReminderTimes,
      categoryLabel: categoryLabel,
      categoryColor: categoryColor,
      categoryIconCodePoint: categoryIconCodePoint,
      frequencyLabel: frequencyLabel,
      active: active,
    );
  }
}
