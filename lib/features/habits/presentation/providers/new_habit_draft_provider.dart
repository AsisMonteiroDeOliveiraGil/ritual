import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewHabitDraft {
  final String name;
  final String description;
  final String haId;
  final String categoryLabel;
  final int? categoryIconCodePoint;
  final int? categoryColor;
  final String iconName;
  final int color;
  final int priority;
  final DateTime startDate;
  final DateTime? endDate;
  final int reminderCount;
  final String frequencyLabel;

  const NewHabitDraft({
    required this.name,
    required this.description,
    required this.haId,
    required this.categoryLabel,
    required this.categoryIconCodePoint,
    required this.categoryColor,
    required this.iconName,
    required this.color,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.reminderCount,
    required this.frequencyLabel,
  });

  NewHabitDraft copyWith({
    String? name,
    String? description,
    String? haId,
    String? categoryLabel,
    int? categoryIconCodePoint,
    int? categoryColor,
    String? iconName,
    int? color,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? reminderCount,
    String? frequencyLabel,
  }) {
    return NewHabitDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      haId: haId ?? this.haId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      categoryIconCodePoint:
          categoryIconCodePoint ?? this.categoryIconCodePoint,
      categoryColor: categoryColor ?? this.categoryColor,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderCount: reminderCount ?? this.reminderCount,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
    );
  }
}

class NewHabitDraftNotifier extends StateNotifier<NewHabitDraft> {
  NewHabitDraftNotifier()
      : super(
          NewHabitDraft(
            name: 'rutina de piel',
            description: 'rutina de piel',
            haId: 'piel_karen',
            categoryLabel: 'Salud',
            categoryIconCodePoint: null,
            categoryColor: 0xFF7FC34A,
            iconName: 'check',
            color: 0xFF7FC34A,
            priority: 1,
            startDate: DateTime.now(),
            endDate: null,
            reminderCount: 0,
            frequencyLabel: 'Cada día',
          ),
        );

  void setCategory({
    required String label,
    required int iconCodePoint,
    required int color,
    required String iconName,
  }) {
    state = state.copyWith(
      categoryLabel: label,
      categoryIconCodePoint: iconCodePoint,
      categoryColor: color,
      iconName: iconName,
      color: color,
    );
  }

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setHaId(String value) {
    state = state.copyWith(haId: value);
  }

  void setStartDate(DateTime value) {
    state = state.copyWith(startDate: value);
  }

  void setEndDate(DateTime? value) {
    state = state.copyWith(endDate: value);
  }

  void setPriority(int value) {
    state = state.copyWith(priority: value);
  }

  void setReminderCount(int value) {
    state = state.copyWith(reminderCount: value);
  }

  void setFrequencyLabel(String value) {
    state = state.copyWith(frequencyLabel: value);
  }

  void reset() {
    state = NewHabitDraft(
      name: '',
      description: '',
      haId: '',
      categoryLabel: '',
      categoryIconCodePoint: null,
      categoryColor: null,
      iconName: 'check',
      color: 0xFFC63C54,
      priority: 1,
      startDate: DateTime.now(),
      endDate: null,
      reminderCount: 0,
      frequencyLabel: 'Cada día',
    );
  }
}

final newHabitDraftProvider =
    StateNotifierProvider<NewHabitDraftNotifier, NewHabitDraft>(
  (ref) => NewHabitDraftNotifier(),
);
