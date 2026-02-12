import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class MarkHabitDone {
  final HabitsRepository _repository;

  MarkHabitDone(this._repository);

  Future<void> call(String habitId, String dateKey, {String source = 'app'}) {
    return _repository.markDone(habitId, dateKey, source: source);
  }
}
