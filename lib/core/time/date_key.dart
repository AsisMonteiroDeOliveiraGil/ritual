String dateKeyFromNowEuropeMadrid() {
  return dateKeyFromDateTime(DateTime.now());
}

String dateKeyFromTimestampEuropeMadrid(int ms) {
  return dateKeyFromDateTime(DateTime.fromMillisecondsSinceEpoch(ms));
}

String dateKeyFromDateTime(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime dateFromDateKey(String dateKey) {
  return DateTime.parse(dateKey);
}

List<String> dateKeysForLastNDays(int days, {DateTime? now}) {
  final base = now ?? DateTime.now();
  return List.generate(days, (index) {
    final dt = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: days - 1 - index));
    return dateKeyFromDateTime(dt);
  });
}
