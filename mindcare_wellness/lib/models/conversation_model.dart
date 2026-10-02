import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.studentId,
    required this.counselorId,
    required this.appointmentId,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String counselorId;
  final String appointmentId;
  final String status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ConversationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ConversationModel(
      id: snapshot.id,
      studentId: data['studentId'] as String? ?? '',
      counselorId: data['counselorId'] as String? ?? '',
      appointmentId: data['appointmentId'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: firestoreDate(data['lastMessageAt']),
      createdAt: firestoreDate(data['createdAt']),
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'counselorId': counselorId,
    'appointmentId': appointmentId,
    'status': status,
    'lastMessage': lastMessage,
    'lastMessageAt': firestoreTimestamp(lastMessageAt),
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
