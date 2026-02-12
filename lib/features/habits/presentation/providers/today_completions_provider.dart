import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayCompletionsNotifier
    extends StateNotifier<Map<String, Set<String>>> {
  TodayCompletionsNotifier() : super(const {});

  void toggleCompletion(String dateKey, String habitId) {
    final current = state[dateKey] ?? <String>{};
    final nextSet = <String>{...current};
    if (nextSet.contains(habitId)) {
      nextSet.remove(habitId);
    } else {
      nextSet.add(habitId);
    }
    state = {
      ...state,
      dateKey: nextSet,
    };
  }

  bool isCompleted(String dateKey, String habitId) {
    return state[dateKey]?.contains(habitId) ?? false;
  }
}

final todayCompletionsProvider =
    StateNotifierProvider<TodayCompletionsNotifier, Map<String, Set<String>>>(
  (ref) => TodayCompletionsNotifier(),
);
