class Completion {
  final String id;
  final String habitId;
  final String dateKey;
  final String source;
  final int timestamp;

  const Completion({
    required this.id,
    required this.habitId,
    required this.dateKey,
    required this.source,
    required this.timestamp,
  });
}
