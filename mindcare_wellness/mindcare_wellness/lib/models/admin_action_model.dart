import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class AdminActionModel {
  const AdminActionModel({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetUserId,
    required this.targetRole,
    this.reason,
    this.createdAt,
  });

  final String id;
  final String adminId;
  final String action;
  final String targetUserId;
  final String targetRole;
  final String? reason;
  final DateTime? createdAt;

  factory AdminActionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AdminActionModel(
      id: snapshot.id,
      adminId: data['adminId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetUserId: data['targetUserId'] as String? ?? '',
      targetRole: data['targetRole'] as String? ?? '',
      reason: data['reason'] as String?,
      createdAt: firestoreDate(data['createdAt'] ?? data['timestamp']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'adminId': adminId,
    'action': action,
    'targetUserId': targetUserId,
    'targetRole': targetRole,
    'reason': reason,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
  };
}
