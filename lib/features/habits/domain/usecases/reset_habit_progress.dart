import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class ResetHabitProgress {
  final HabitsRepository _repository;

  ResetHabitProgress(this._repository);

  Future<void> call(String habitId) {
    return _repository.resetHabitProgress(habitId);
  }
}
