class HabitStats {
  final String habitId;
  final int currentStreak;
  final int maxStreak;
  final double percent7;
  final double percent30;
  final double percent90;
  final List<int> last30Days; // 1 for completed, 0 for not

  const HabitStats({
    required this.habitId,
    required this.currentStreak,
    required this.maxStreak,
    required this.percent7,
    required this.percent30,
    required this.percent90,
    required this.last30Days,
  });
}
