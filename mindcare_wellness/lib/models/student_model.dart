import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class StudentModel {
  const StudentModel({
    required this.uid,
    this.studentId,
    this.alias,
    this.faculty,
    this.department,
    this.degreeProgram,
    this.academicYear,
    this.batch,
    this.priorityLevel = 'normal',
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? studentId;
  final String? alias;
  final String? faculty;
  final String? department;
  final String? degreeProgram;
  final String? academicYear;
  final String? batch;
  final String priorityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isHighPriority => priorityLevel == 'high';

  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return StudentModel(
      uid: data['uid'] as String? ?? snapshot.id,
      studentId: data['studentId'] as String?,
      alias: data['alias'] as String?,
      faculty: data['faculty'] as String?,
      department: data['department'] as String?,
      degreeProgram: data['degreeProgram'] as String?,
      academicYear: data['academicYear']?.toString(),
      batch: (data['batch'] ?? data['intake'])?.toString(),
      priorityLevel: data['priorityLevel'] as String? ?? 'normal',
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'studentId': studentId,
    'alias': alias,
    'faculty': faculty,
    'department': department,
    'degreeProgram': degreeProgram,
    'academicYear': academicYear,
    'batch': batch,
    'priorityLevel': priorityLevel,
    'createdAt': firestoreTimestamp(createdAt),
    'updatedAt': firestoreTimestamp(updatedAt),
  };
}
