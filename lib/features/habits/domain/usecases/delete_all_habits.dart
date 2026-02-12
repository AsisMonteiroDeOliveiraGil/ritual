import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class DeleteAllHabits {
  final HabitsRepository _repository;

  DeleteAllHabits(this._repository);

  Future<void> call() => _repository.deleteAllHabitsAndCompletions();
}
