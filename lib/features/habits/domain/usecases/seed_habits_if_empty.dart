import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class SeedHabitsIfEmpty {
  final HabitsRepository _repository;

  SeedHabitsIfEmpty(this._repository);

  Future<void> call() => _repository.seedHabitsIfEmpty();
}
