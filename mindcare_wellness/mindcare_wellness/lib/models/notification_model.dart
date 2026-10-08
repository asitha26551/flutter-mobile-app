import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return NotificationModel(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      relatedId: data['relatedId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: firestoreDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type,
    'relatedId': relatedId,
    'isRead': isRead,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
  };
}
