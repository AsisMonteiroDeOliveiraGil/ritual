import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class UnmarkHabitDone {
  final HabitsRepository _repository;

  UnmarkHabitDone(this._repository);

  Future<void> call(String habitId, String dateKey) {
    return _repository.unmarkDone(habitId, dateKey);
  }
}
