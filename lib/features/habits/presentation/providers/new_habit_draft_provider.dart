import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewHabitDraft {
  final String name;
  final String description;
  final String haId;
  final String categoryLabel;
  final String iconName;
  final int color;
  final int priority;
  final DateTime startDate;
  final DateTime? endDate;
  final int reminderCount;

  const NewHabitDraft({
    required this.name,
    required this.description,
    required this.haId,
    required this.categoryLabel,
    required this.iconName,
    required this.color,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.reminderCount,
  });

  NewHabitDraft copyWith({
    String? name,
    String? description,
    String? haId,
    String? categoryLabel,
    String? iconName,
    int? color,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? reminderCount,
  }) {
    return NewHabitDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      haId: haId ?? this.haId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderCount: reminderCount ?? this.reminderCount,
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
            iconName: 'check',
            color: 0xFF7FC34A,
            priority: 1,
            startDate: DateTime.now(),
            endDate: null,
            reminderCount: 0,
          ),
        );

  void setCategory({
    required String label,
    required String iconName,
    required int color,
  }) {
    state = state.copyWith(
      categoryLabel: label,
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

  void reset() {
    state = NewHabitDraft(
      name: '',
      description: '',
      haId: '',
      categoryLabel: '',
      iconName: 'check',
      color: 0xFFC63C54,
      priority: 1,
      startDate: DateTime.now(),
      endDate: null,
      reminderCount: 0,
    );
  }
}

final newHabitDraftProvider =
    StateNotifierProvider<NewHabitDraftNotifier, NewHabitDraft>(
  (ref) => NewHabitDraftNotifier(),
);
