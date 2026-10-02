import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.message,
    required this.isRead,
    this.attachmentUrl,
    this.sentAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String messageType;
  final String message;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime? sentAt;

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return MessageModel(
      id: snapshot.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      messageType: data['messageType'] as String? ?? 'text',
      message: data['message'] as String? ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      sentAt: firestoreDate(data['sentAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'receiverId': receiverId,
    'messageType': messageType,
    'message': message,
    'attachmentUrl': attachmentUrl,
    'isRead': isRead,
    'sentAt': firestoreTimestamp(sentAt) ?? FieldValue.serverTimestamp(),
  };
}
