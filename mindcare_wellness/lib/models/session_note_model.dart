import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class SessionNoteModel {
  const SessionNoteModel({
    required this.id,
    required this.appointmentId,
    required this.studentId,
    required this.counselorId,
    required this.summary,
    required this.observations,
    required this.followUpPlan,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String appointmentId;
  final String studentId;
  final String counselorId;
  final String summary;
  final String observations;
  final String followUpPlan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SessionNoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return SessionNoteModel(
      id: snapshot.id,
      appointmentId: data['appointmentId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      counselorId: data['counselorId'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      observations: data['observations'] as String? ?? '',
      followUpPlan: data['followUpPlan'] as String? ?? '',
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'appointmentId': appointmentId,
    'studentId': studentId,
    'counselorId': counselorId,
    'summary': summary,
    'observations': observations,
    'followUpPlan': followUpPlan,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
