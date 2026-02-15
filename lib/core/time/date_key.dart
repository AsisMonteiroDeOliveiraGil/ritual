const int kLogicalDayCutoffHour = 4;

String dateKeyFromNowEuropeMadrid() {
  return dateKeyFromDateTime(logicalDateFromDateTime(DateTime.now()));
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

DateTime logicalDateFromDateTime(DateTime dateTime, {int cutoffHour = kLogicalDayCutoffHour}) {
  final shifted = dateTime.subtract(Duration(hours: cutoffHour));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

String logicalDateKeyFromNow({DateTime? now, int cutoffHour = kLogicalDayCutoffHour}) {
  return dateKeyFromDateTime(
    logicalDateFromDateTime(now ?? DateTime.now(), cutoffHour: cutoffHour),
  );
}

DateTime nextLogicalDayBoundary(DateTime now, {int cutoffHour = kLogicalDayCutoffHour}) {
  final boundary = DateTime(now.year, now.month, now.day, cutoffHour);
  if (boundary.isAfter(now)) return boundary;
  return boundary.add(const Duration(days: 1));
}

DateTime dateFromDateKey(String dateKey) {
  return DateTime.parse(dateKey);
}

List<String> dateKeysForLastNDays(int days, {DateTime? now}) {
  final base = logicalDateFromDateTime(now ?? DateTime.now());
  return List.generate(days, (index) {
    final dt = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: days - 1 - index));
    return dateKeyFromDateTime(dt);
  });
}
