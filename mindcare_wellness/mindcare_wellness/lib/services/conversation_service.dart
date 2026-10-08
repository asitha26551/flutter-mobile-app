import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/conversation_model.dart';

class ConversationService {
  ConversationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<ConversationModel>> forStudent() => _query('studentId');
  Stream<List<ConversationModel>> forCounselor() => _query('counselorId');

  Stream<List<ConversationModel>> _query(String field) => _firestore
      .collection('conversations')
      .where(field, isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ConversationModel.fromFirestore).toList());

  Future<String> create({
    required String studentId,
    required String counselorId,
    required String appointmentId,
  }) async {
    final reference = _firestore.collection('conversations').doc();
    await reference.set({
      'studentId': studentId,
      'counselorId': counselorId,
      'appointmentId': appointmentId,
      'status': 'active',
      'lastMessage': null,
      'lastMessageAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> close(String conversationId) =>
      _firestore.collection('conversations').doc(conversationId).update({
        'status': 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
