import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ritual/features/habits/data/dtos/completion_dto.dart';
import 'package:ritual/features/habits/data/dtos/habit_dto.dart';

class FirestoreHabitsDataSource {
  final FirebaseFirestore firestore;
  final String uid;

  FirestoreHabitsDataSource({required this.firestore, required this.uid});

  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      firestore.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> get _completionsRef =>
      firestore.collection('users').doc(uid).collection('completions');

  Stream<List<HabitDto>> watchActiveHabits() {
    return _habitsRef
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(HabitDto.fromFirestore).toList());
  }

  Stream<Map<String, CompletionDto>> watchCompletionsForDate(String dateKey) {
    return _completionsRef
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) {
      final map = <String, CompletionDto>{};
      for (final doc in snapshot.docs) {
        final dto = CompletionDto.fromFirestore(doc);
        map[dto.habitId] = dto;
      }
      return map;
    });
  }

  Stream<List<CompletionDto>> watchCompletionsRange(
    String habitId,
    String fromDateKey,
    String toDateKey,
  ) {
    return _completionsRef
        .where('habitId', isEqualTo: habitId)
        .where('dateKey', isGreaterThanOrEqualTo: fromDateKey)
        .where('dateKey', isLessThanOrEqualTo: toDateKey)
        .orderBy('dateKey')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CompletionDto.fromFirestore).toList());
  }

  Future<void> markDone({
    required String habitId,
    required String dateKey,
    required String source,
    required int timestamp,
  }) async {
    final docId = '${habitId}_$dateKey';
    final docRef = _completionsRef.doc(docId);
    final existing = await docRef.get();
    if (existing.exists) {
      return;
    }
    final dto = CompletionDto(
      id: docId,
      habitId: habitId,
      dateKey: dateKey,
      source: source,
      timestamp: timestamp,
    );
    await docRef.set(dto.toFirestore());
  }

  Future<void> unmarkDone({
    required String habitId,
    required String dateKey,
  }) async {
    final docId = '${habitId}_$dateKey';
    await _completionsRef.doc(docId).delete();
  }

  Future<void> seedHabitsIfEmpty(List<HabitDto> habits) async {
    final snapshot = await _habitsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }
    final batch = firestore.batch();
    for (final habit in habits) {
      final docRef = _habitsRef.doc(habit.id);
      batch.set(docRef, habit.toFirestore());
    }
    await batch.commit();
  }

  Future<void> createHabit({
    required String name,
    required String icon,
    required int color,
    String? description,
    String? haId,
    bool active = true,
    int? order,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? reminderCount,
  }) async {
    final docRef = _habitsRef.doc();
    final normalizedName = _normalizeKey(name);
    final slug = _slugifyName(name);
    final code = '${slug}_${docRef.id.substring(0, 4)}';
    final payload = <String, dynamic>{
      'name': name,
      'nameLower': normalizedName,
      'code': code,
      if (haId != null && haId.trim().isNotEmpty) 'haId': haId.trim(),
      'icon': icon,
      'color': color,
      'active': active,
      'order': order ?? DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (priority != null) {
      payload['priority'] = priority;
    }
    if (startDate != null) {
      payload['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) {
      payload['endDate'] = Timestamp.fromDate(endDate);
    }
    if (reminderCount != null) {
      payload['reminderCount'] = reminderCount;
    }
    await docRef.set(payload);
  }

  String _normalizeKey(String value) {
    return _stripDiacritics(value)
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _slugifyName(String value) {
    final normalized = _stripDiacritics(value)
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .replaceAll(RegExp(r'_{2,}'), '_');
    return normalized.isEmpty ? 'habit' : normalized;
  }

  String _stripDiacritics(String value) {
    return value
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N');
  }

  Future<void> deleteAllHabitsAndCompletions() async {
    await _deleteCollection(_habitsRef);
    await _deleteCollection(_completionsRef);
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    const batchLimit = 400;
    while (true) {
      final snapshot = await ref.limit(batchLimit).get();
      if (snapshot.docs.isEmpty) {
        break;
      }
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
