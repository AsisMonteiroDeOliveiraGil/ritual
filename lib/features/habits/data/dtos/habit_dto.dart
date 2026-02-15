import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';

class HabitDto {
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

  const HabitDto({
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

  factory HabitDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HabitDto(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      icon: (data['icon'] ?? '') as String,
      color: _parseColor(data['color']),
      active: (data['active'] ?? true) as bool,
      order: (data['order'] ?? 0) as int,
      description: data['description'] as String?,
      haId: data['haId'] as String?,
      priority: _parseInt(data['priority']),
      reminderCount: _parseInt(data['reminderCount']),
      reminderTimes: _parseStringList(data['reminderTimes']),
      categoryLabel: data['categoryLabel'] as String?,
      categoryColor: _parseInt(data['categoryColor']),
      categoryIconCodePoint: _parseInt(data['categoryIconCodePoint']),
      frequencyLabel: data['frequencyLabel'] as String?,
      startDate: _parseTimestamp(data['startDate']),
      endDate: _parseTimestamp(data['endDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'active': active,
      'order': order,
      if (description != null) 'description': description,
      if (haId != null) 'haId': haId,
      if (priority != null) 'priority': priority,
      if (reminderCount != null) 'reminderCount': reminderCount,
      if (reminderTimes != null) 'reminderTimes': reminderTimes,
      if (categoryLabel != null) 'categoryLabel': categoryLabel,
      if (categoryColor != null) 'categoryColor': categoryColor,
      if (categoryIconCodePoint != null)
        'categoryIconCodePoint': categoryIconCodePoint,
      if (frequencyLabel != null) 'frequencyLabel': frequencyLabel,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      icon: icon,
      color: color,
      active: active,
      order: order,
      description: description,
      haId: haId,
      priority: priority,
      reminderCount: reminderCount,
      reminderTimes: reminderTimes,
      categoryLabel: categoryLabel,
      categoryColor: categoryColor,
      categoryIconCodePoint: categoryIconCodePoint,
      frequencyLabel: frequencyLabel,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static int _parseColor(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final cleaned = value.replaceAll('#', '').replaceAll('0x', '');
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        if (cleaned.length <= 6) {
          return 0xFF000000 | parsed;
        }
        return parsed;
      }
    }
    return 0xFF2D3748;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }
}
