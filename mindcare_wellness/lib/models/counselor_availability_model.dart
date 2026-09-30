import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class CounselorAvailabilityModel {
  const CounselorAvailabilityModel({
    required this.id,
    required this.counselorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.sessionDuration,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String counselorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int sessionDuration;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CounselorAvailabilityModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return CounselorAvailabilityModel(
      id: snapshot.id,
      counselorId: data['counselorId'] as String? ?? '',
      dayOfWeek: data['dayOfWeek'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      sessionDuration: (data['sessionDuration'] as num?)?.toInt() ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? false,
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'counselorId': counselorId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'sessionDuration': sessionDuration,
    'isAvailable': isAvailable,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
