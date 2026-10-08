import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/journal_entry_model.dart';

class JournalService {
  JournalService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<JournalEntryModel>> mine() => _firestore
      .collection('journal_entries')
      .where('studentId', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(JournalEntryModel.fromFirestore).toList());

  Future<String> create({required String title, required String content, String? mood}) async {
    final reference = _firestore.collection('journal_entries').doc();
    await reference.set({
      'studentId': uid,
      'title': title,
      'content': content,
      'mood': mood,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> update(String id, {required String title, required String content, String? mood}) =>
      _firestore.collection('journal_entries').doc(id).update({
        'title': title,
        'content': content,
        'mood': mood,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _firestore.collection('journal_entries').doc(id).delete();
}
