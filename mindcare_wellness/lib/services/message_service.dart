import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

class MessageService {
  MessageService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<MessageModel>> forConversation(String conversationId) => _firestore
      .collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('sentAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MessageModel.fromFirestore).toList());

  Future<String> send({
    required String conversationId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    final reference = _firestore.collection('messages').doc();
    await reference.set({
      'conversationId': conversationId,
      'senderId': uid,
      'receiverId': receiverId,
      'messageType': messageType,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> markRead(String messageId) =>
      _firestore.collection('messages').doc(messageId).update({'isRead': true});
}
