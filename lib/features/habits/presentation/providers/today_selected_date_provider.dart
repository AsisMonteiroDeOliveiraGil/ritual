import 'package:ritual/core/time/date_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todaySelectedDateProvider = StateProvider<DateTime>((ref) {
  return logicalDateFromDateTime(DateTime.now());
});
