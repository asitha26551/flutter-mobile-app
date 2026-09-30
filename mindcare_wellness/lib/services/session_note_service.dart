import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_note_model.dart';

class SessionNoteService {
  SessionNoteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<SessionNoteModel>> forCounselor() => _firestore
      .collection('session_notes')
      .where('counselorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(SessionNoteModel.fromFirestore).toList());

  Future<String> create({
    required String appointmentId,
    required String studentId,
    required String summary,
    required String observations,
    required String followUpPlan,
  }) async {
    final reference = _firestore.collection('session_notes').doc();
    await reference.set({
      'appointmentId': appointmentId,
      'studentId': studentId,
      'counselorId': uid,
      'summary': summary,
      'observations': observations,
      'followUpPlan': followUpPlan,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> update(
    String id, {
    required String summary,
    required String observations,
    required String followUpPlan,
  }) => _firestore.collection('session_notes').doc(id).update({
    'summary': summary,
    'observations': observations,
    'followUpPlan': followUpPlan,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
