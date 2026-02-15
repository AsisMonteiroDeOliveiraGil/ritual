import 'package:ritual/features/habits/data/datasources/firestore_habits_datasource.dart';
import 'package:ritual/features/habits/data/dtos/habit_dto.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/repositories/habits_repository.dart';

class FirestoreHabitsRepository implements HabitsRepository {
  final FirestoreHabitsDataSource _dataSource;

  FirestoreHabitsRepository(this._dataSource);

  @override
  Stream<List<Habit>> watchActiveHabits() {
    return _dataSource.watchActiveHabits().map(
          (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
        );
  }

  @override
  Stream<Map<String, Completion>> watchCompletionsForDate(String dateKey) {
    return _dataSource.watchCompletionsForDate(dateKey).map((map) {
      return map.map((key, dto) => MapEntry(key, dto.toEntity()));
    });
  }

  @override
  Stream<List<Completion>> watchCompletionsRange(
    String habitId,
    String fromDateKey,
    String toDateKey,
  ) {
    return _dataSource
        .watchCompletionsRange(habitId, fromDateKey, toDateKey)
        .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());
  }

  @override
  Future<void> markDone(String habitId, String dateKey, {String source = 'app'}) {
    return _dataSource.markDone(
      habitId: habitId,
      dateKey: dateKey,
      source: source,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> unmarkDone(String habitId, String dateKey) {
    return _dataSource.unmarkDone(
      habitId: habitId,
      dateKey: dateKey,
    );
  }

  @override
  Future<void> createHabit({
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
    List<String>? reminderTimes,
    String? categoryLabel,
    int? categoryColor,
    int? categoryIconCodePoint,
    String? frequencyLabel,
  }) {
    return _dataSource.createHabit(
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
      reminderTimes: reminderTimes,
      categoryLabel: categoryLabel,
      categoryColor: categoryColor,
      categoryIconCodePoint: categoryIconCodePoint,
      frequencyLabel: frequencyLabel,
    );
  }

  @override
  Future<void> updateHabit({
    required String habitId,
    String? name,
    String? description,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool setEndDate = false,
    int? reminderCount,
    List<String>? reminderTimes,
    bool setReminderTimes = false,
    String? categoryLabel,
    int? categoryColor,
    int? categoryIconCodePoint,
    String? frequencyLabel,
    bool? active,
  }) {
    return _dataSource.updateHabit(
      habitId: habitId,
      name: name,
      description: description,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      setEndDate: setEndDate,
      reminderCount: reminderCount,
      reminderTimes: reminderTimes,
      setReminderTimes: setReminderTimes,
      categoryLabel: categoryLabel,
      categoryColor: categoryColor,
      categoryIconCodePoint: categoryIconCodePoint,
      frequencyLabel: frequencyLabel,
      active: active,
    );
  }

  @override
  Future<void> deleteHabit(String habitId) {
    return _dataSource.deleteHabit(habitId);
  }

  @override
  Future<void> resetHabitProgress(String habitId) {
    return _dataSource.resetHabitProgress(habitId);
  }

  @override
  Future<void> deleteAllHabitsAndCompletions() {
    return _dataSource.deleteAllHabitsAndCompletions();
  }

  @override
  Future<void> seedHabitsIfEmpty() async {
    final habits = <HabitDto>[
      const HabitDto(
        id: 'agua_despertar',
        name: 'Agua al despertar',
        icon: 'water',
        color: 0xFF1C7ED6,
        active: true,
        order: 1,
      ),
      const HabitDto(
        id: 'vitaminas',
        name: 'Vitaminas',
        icon: 'pill',
        color: 0xFF37B24D,
        active: true,
        order: 2,
      ),
      const HabitDto(
        id: 'skin_am',
        name: 'Piel AM',
        icon: 'sun',
        color: 0xFFF59F00,
        active: true,
        order: 3,
      ),
      const HabitDto(
        id: 'skin_pm',
        name: 'Piel PM',
        icon: 'moon',
        color: 0xFF7048E8,
        active: true,
        order: 4,
      ),
    ];
    await _dataSource.seedHabitsIfEmpty(habits);
  }
}
