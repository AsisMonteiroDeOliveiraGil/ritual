import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class WatchActiveHabits {
  final HabitsRepository _repository;

  WatchActiveHabits(this._repository);

  Stream<List<Habit>> call() => _repository.watchActiveHabits();
}
