import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class DeleteHabit {
  final HabitsRepository _repository;

  DeleteHabit(this._repository);

  Future<void> call(String habitId) {
    return _repository.deleteHabit(habitId);
  }
}
