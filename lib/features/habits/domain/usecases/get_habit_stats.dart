import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit_stats.dart';
import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class GetHabitStats {
  final HabitsRepository _repository;

  GetHabitStats(this._repository);

  Stream<HabitStats> call(String habitId) {
    final now = DateTime.now();
    final from = dateKeyFromDateTime(
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 364)),
    );
    final to = dateKeyFromDateTime(DateTime(now.year, now.month, now.day));

    return _repository
        .watchCompletionsRange(habitId, from, to)
        .map((completions) => _buildStats(habitId, completions, now));
  }

  HabitStats _buildStats(
    String habitId,
    List<Completion> completions,
    DateTime now,
  ) {
    final completedKeys = completions.map((c) => c.dateKey).toSet();
    final last7 = dateKeysForLastNDays(7, now: now);
    final last30 = dateKeysForLastNDays(30, now: now);
    final last90 = dateKeysForLastNDays(90, now: now);
    final last365 = dateKeysForLastNDays(365, now: now);

    int countIn(List<String> keys) {
      var count = 0;
      for (final key in keys) {
        if (completedKeys.contains(key)) count++;
      }
      return count;
    }

    int currentStreak() {
      var streak = 0;
      for (var i = last365.length - 1; i >= 0; i--) {
        final key = last365[i];
        if (completedKeys.contains(key)) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }

    int maxStreak() {
      var max = 0;
      var streak = 0;
      for (final key in last365) {
        if (completedKeys.contains(key)) {
          streak++;
          if (streak > max) max = streak;
        } else {
          streak = 0;
        }
      }
      return max;
    }

    final count7 = countIn(last7);
    final count30 = countIn(last30);
    final count90 = countIn(last90);

    return HabitStats(
      habitId: habitId,
      currentStreak: currentStreak(),
      maxStreak: maxStreak(),
      percent7: count7 / 7,
      percent30: count30 / 30,
      percent90: count90 / 90,
      last30Days: last30
          .map((key) => completedKeys.contains(key) ? 1 : 0)
          .toList(),
    );
  }
}
