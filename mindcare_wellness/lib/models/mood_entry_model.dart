import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class MoodEntryModel {
  const MoodEntryModel({
    required this.id,
    required this.studentId,
    required this.mood,
    required this.moodScore,
    this.stressLevel,
    this.note,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String mood;
  final int moodScore;

  // Stress level from 1 - 5
  final int? stressLevel;

  final String? note;
  final DateTime? createdAt;

  factory MoodEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return MoodEntryModel(
      id: snapshot.id,
      studentId: data['studentId'] as String? ?? '',
      mood: data['mood'] as String? ?? '',
      moodScore: (data['moodScore'] as num?)?.toInt() ?? 0,
      stressLevel: (data['stressLevel'] as num?)?.toInt(),
      note: data['note'] as String?,
      createdAt: firestoreDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'mood': mood,
        'moodScore': moodScore,
        'stressLevel': stressLevel,
        'note': note,
        'createdAt':
            firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
      };
}