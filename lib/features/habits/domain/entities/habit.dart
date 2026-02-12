class Habit {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool active;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.active,
    required this.order,
    this.startDate,
    this.endDate,
  });
}
