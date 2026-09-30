import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mood_entry_model.dart';

class MoodService {
  MoodService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<MoodEntryModel>> mine() => _firestore
      .collection('mood_entries')
      .where('studentId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MoodEntryModel.fromFirestore).toList());

  Future<String> create({
    required String mood,
    required int moodScore,
    String? note,
  }) async {
    final reference = _firestore.collection('mood_entries').doc();
    await reference.set({
      'studentId': uid,
      'mood': mood,
      'moodScore': moodScore,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> update(String id, {required String mood, required int moodScore, String? note}) =>
      _firestore.collection('mood_entries').doc(id).update({
        'mood': mood,
        'moodScore': moodScore,
        'note': note,
      });

  Future<void> delete(String id) => _firestore.collection('mood_entries').doc(id).delete();
}
