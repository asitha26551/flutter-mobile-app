import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.studentId,
    required this.counselorId,
    required this.startAt,
    required this.endAt,
    required this.sessionType,
    required this.status,
    this.reason,
    this.meetingLink,
    this.location,
    this.studentNotes,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String counselorId;
  final DateTime? startAt;
  final DateTime? endAt;
  final String sessionType;
  final String status;
  final String? reason;
  final String? meetingLink;
  final String? location;
  final String? studentNotes;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // --- Convenience Getters ---
  bool get isUpcoming =>
      (status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'confirmed') &&
      !isCancelled;
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'past';

  AppointmentModel copyWith({
    String? id,
    String? studentId,
    String? counselorId,
    DateTime? startAt,
    DateTime? endAt,
    String? sessionType,
    String? status,
    String? reason,
    String? meetingLink,
    String? location,
    String? studentNotes,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppointmentModel(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        counselorId: counselorId ?? this.counselorId,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        sessionType: sessionType ?? this.sessionType,
        status: status ?? this.status,
        reason: reason ?? this.reason,
        meetingLink: meetingLink ?? this.meetingLink,
        location: location ?? this.location,
        studentNotes: studentNotes ?? this.studentNotes,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        cancelledBy: cancelledBy ?? this.cancelledBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory AppointmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AppointmentModel(
      id: snapshot.id,
      studentId: data['studentId'] as String? ?? data['userId'] as String? ?? '',
      counselorId: data['counselorId'] as String? ?? '',
      startAt: firestoreDate(data['startAt'] ?? data['appointmentDate']),
      endAt: firestoreDate(data['endAt']),
      sessionType: data['sessionType'] as String? ?? data['type'] as String? ?? 'chat',
      status: data['status'] as String? ?? 'pending',
      reason: data['reason'] as String?,
      meetingLink: data['meetingLink'] as String?,
      location: data['location'] as String?,
      studentNotes: data['studentNotes'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> data) =>
      AppointmentModel(
        id: id,
        studentId: data['studentId'] as String? ?? data['userId'] as String? ?? '',
        counselorId: data['counselorId'] as String? ?? '',
        startAt: firestoreDate(data['startAt'] ?? data['appointmentDate']),
        endAt: firestoreDate(data['endAt']),
        sessionType: data['sessionType'] as String? ?? data['type'] as String? ?? 'chat',
        status: data['status'] as String? ?? 'pending',
        reason: data['reason'] as String?,
        meetingLink: data['meetingLink'] as String?,
        location: data['location'] as String?,
        studentNotes: data['studentNotes'] as String?,
        cancellationReason: data['cancellationReason'] as String?,
        cancelledBy: data['cancelledBy'] as String?,
        createdAt: firestoreDate(data['createdAt']),
        updatedAt: firestoreDate(data['updatedAt']),
      );

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'userId': studentId,
    'counselorId': counselorId,
    'startAt': firestoreTimestamp(startAt),
    'appointmentDate': firestoreTimestamp(startAt),
    'endAt': firestoreTimestamp(endAt),
    'sessionType': sessionType,
    'type': sessionType,
    'status': status,
    'reason': reason,
    'studentAlias': studentId,
    'meetingLink': meetingLink,
    'location': location,
    'studentNotes': studentNotes,
    'cancellationReason': cancellationReason,
    'cancelledBy': cancelledBy,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          counselorId == other.counselorId &&
          startAt == other.startAt &&
          endAt == other.endAt &&
          sessionType == other.sessionType &&
          status == other.status &&
          reason == other.reason &&
          studentNotes == other.studentNotes;

  @override
  int get hashCode => Object.hash(
        id,
        studentId,
        counselorId,
        startAt,
        endAt,
        sessionType,
        status,
        reason,
        studentNotes,
      );
}
