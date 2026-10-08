import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class SessionNoteModel {
  const SessionNoteModel({
    required this.id,
    required this.appointmentId,
    required this.studentId,
    required this.counselorId,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String appointmentId;
  final String studentId;
  final String counselorId;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SessionNoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return SessionNoteModel(
      id: snapshot.id,
      appointmentId: data['appointmentId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      counselorId: data['counselorId'] as String? ?? '',
      note: data['note'] as String? ?? _legacyNote(data),
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  String get summary => note;

  static String _legacyNote(Map<String, dynamic> data) => [
    data['summary'] as String? ?? '',
    data['observations'] as String? ?? '',
    data['followUpPlan'] as String? ?? '',
  ].where((value) => value.trim().isNotEmpty).join('\n\n');

  Map<String, dynamic> toFirestore() => {
    'appointmentId': appointmentId,
    'studentId': studentId,
    'counselorId': counselorId,
    'note': note,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
