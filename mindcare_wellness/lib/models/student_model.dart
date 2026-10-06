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
    this.isAnonymous = false,
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
  final bool isAnonymous;
  final String priorityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isHighPriority => priorityLevel == 'high';

  String counselorDisplayName({String? fullName}) {
    if (isAnonymous) {
      final aliasValue = alias?.trim();
      if (aliasValue != null && aliasValue.isNotEmpty) return aliasValue;
      return 'Anonymous student';
    }

    final trimmedFullName = (fullName ?? '').trim();
    if (trimmedFullName.isNotEmpty) return trimmedFullName;

    final aliasValue = alias?.trim();
    if (aliasValue != null && aliasValue.isNotEmpty) return aliasValue;
    return 'Student';
  }

  bool matchesCounselorSearch(String query, {String? fullName}) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final fullNameValue = (fullName ?? '').trim();
    final aliasValue = alias?.trim() ?? '';
    final haystacks = <String>[
      fullNameValue,
      fullNameValue.toLowerCase(),
    ];

    if (isAnonymous) {
      haystacks.addAll([
        aliasValue,
        aliasValue.toLowerCase(),
      ]);
    }

    return haystacks.any(
      (value) => value.toLowerCase().contains(normalizedQuery.toLowerCase()),
    );
  }

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
      isAnonymous: data['isAnonymous'] as bool? ?? data['anonymousMode'] as bool? ?? false,
      priorityLevel: data['priorityLevel'] as String? ?? 'normal',
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  StudentModel copyWith({
    String? uid,
    String? studentId,
    String? alias,
    String? faculty,
    String? department,
    String? degreeProgram,
    String? academicYear,
    String? batch,
    bool? isAnonymous,
    String? priorityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudentModel(
    uid: uid ?? this.uid,
    studentId: studentId ?? this.studentId,
    alias: alias ?? this.alias,
    faculty: faculty ?? this.faculty,
    department: department ?? this.department,
    degreeProgram: degreeProgram ?? this.degreeProgram,
    academicYear: academicYear ?? this.academicYear,
    batch: batch ?? this.batch,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    priorityLevel: priorityLevel ?? this.priorityLevel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'studentId': studentId,
    'alias': alias,
    'faculty': faculty,
    'department': department,
    'degreeProgram': degreeProgram,
    'academicYear': academicYear,
    'batch': batch,
    'isAnonymous': isAnonymous,
    'priorityLevel': priorityLevel,
    'createdAt': firestoreTimestamp(createdAt),
    'updatedAt': firestoreTimestamp(updatedAt),
  };
}
