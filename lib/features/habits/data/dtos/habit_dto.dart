import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';

class HabitDto {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool active;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;

  const HabitDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.active,
    required this.order,
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
}
