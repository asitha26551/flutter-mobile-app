import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class JournalEntryModel {
  const JournalEntryModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.content,
    this.mood,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String title;
  final String content;
  final String? mood;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory JournalEntryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return JournalEntryModel(
      id: snapshot.id,
      studentId: data['studentId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      mood: data['mood'] as String?,
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'title': title,
    'content': content,
    'mood': mood,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
