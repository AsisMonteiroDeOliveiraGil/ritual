import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class CreateHabit {
  final HabitsRepository _repository;

  CreateHabit(this._repository);

  Future<void> call({
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
  }) {
    return _repository.createHabit(
      name: name,
      icon: icon,
      color: color,
      description: description,
      haId: haId,
      active: active,
      order: order,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      reminderCount: reminderCount,
    );
  }
}
