class Habit {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool active;
  final int order;
  final String? description;
  final String? haId;
  final int? priority;
  final int? reminderCount;
  final List<String>? reminderTimes;
  final String? categoryLabel;
  final int? categoryColor;
  final int? categoryIconCodePoint;
  final String? frequencyLabel;
  final DateTime? startDate;
  final DateTime? endDate;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.active,
    required this.order,
    this.description,
    this.haId,
    this.priority,
    this.reminderCount,
    this.reminderTimes,
    this.categoryLabel,
    this.categoryColor,
    this.categoryIconCodePoint,
    this.frequencyLabel,
    this.startDate,
    this.endDate,
  });
}
