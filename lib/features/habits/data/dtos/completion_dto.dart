import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';

class CompletionDto {
  final String id;
  final String habitId;
  final String dateKey;
  final String source;
  final int timestamp;

  const CompletionDto({
    required this.id,
    required this.habitId,
    required this.dateKey,
    required this.source,
    required this.timestamp,
  });

  factory CompletionDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CompletionDto(
      id: doc.id,
      habitId: (data['habitId'] ?? '') as String,
      dateKey: (data['dateKey'] ?? '') as String,
      source: (data['source'] ?? '') as String,
      timestamp: (data['timestamp'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'dateKey': dateKey,
      'source': source,
      'timestamp': timestamp,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Completion toEntity() {
    return Completion(
      id: id,
      habitId: habitId,
      dateKey: dateKey,
      source: source,
      timestamp: timestamp,
    );
  }
}
