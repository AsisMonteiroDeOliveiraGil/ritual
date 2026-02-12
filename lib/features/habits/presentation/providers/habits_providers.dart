import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/data/datasources/firestore_habits_datasource.dart';
import 'package:ritual/features/habits/data/repositories/firestore_habits_repository.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/entities/habit_stats.dart';
import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';
import 'package:ritual/features/habits/domain/usecases/create_habit.dart';
import 'package:ritual/features/habits/domain/usecases/delete_all_habits.dart';
import 'package:ritual/features/habits/domain/usecases/get_habit_stats.dart';
import 'package:ritual/features/habits/domain/usecases/mark_habit_done.dart';
import 'package:ritual/features/habits/domain/usecases/seed_habits_if_empty.dart';
import 'package:ritual/features/habits/domain/usecases/unmark_habit_done.dart';
import 'package:ritual/features/habits/domain/usecases/watch_active_habits.dart';
import 'package:ritual/features/habits/presentation/providers/auth_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final habitsRepositoryProvider = FutureProvider<HabitsRepository>((ref) async {
  final user = await ref.watch(ensureSignedInProvider.future);
  final firestore = ref.watch(firestoreProvider);
  final datasource =
      FirestoreHabitsDataSource(firestore: firestore, uid: user.uid);
  return FirestoreHabitsRepository(datasource);
});

final watchActiveHabitsProvider = StreamProvider<List<Habit>>((ref) async* {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  yield* WatchActiveHabits(repo).call();
});

final completionsForDateProvider =
    StreamProvider.family<Map<String, Completion>, String>((ref, dateKey) async* {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  yield* repo.watchCompletionsForDate(dateKey);
});

final markHabitDoneProvider = FutureProvider<MarkHabitDone>((ref) async {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  return MarkHabitDone(repo);
});

final unmarkHabitDoneProvider = FutureProvider<UnmarkHabitDone>((ref) async {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  return UnmarkHabitDone(repo);
});

final createHabitProvider = FutureProvider<CreateHabit>((ref) async {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  return CreateHabit(repo);
});

final deleteAllHabitsProvider = FutureProvider<DeleteAllHabits>((ref) async {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  return DeleteAllHabits(repo);
});

final habitStatsProvider =
    StreamProvider.family<HabitStats, String>((ref, habitId) async* {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  yield* GetHabitStats(repo).call(habitId);
});

final habitWeekCompletionsProvider =
    StreamProvider.family<List<Completion>, String>((ref, habitId) async* {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  final now = DateTime.now();
  final from = dateKeyFromDateTime(
    DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
  );
  final to = dateKeyFromDateTime(DateTime(now.year, now.month, now.day));
  yield* repo.watchCompletionsRange(habitId, from, to);
});

final seedHabitsProvider = FutureProvider<SeedHabitsIfEmpty>((ref) async {
  final repo = await ref.watch(habitsRepositoryProvider.future);
  return SeedHabitsIfEmpty(repo);
});
