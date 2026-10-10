import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reminder_preference_model.dart';

/// Reminder preferences: read, save (create/update) and reset (delete).
class ReminderService {
  ReminderService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('reminder_preferences');

  /// READ (live). Emits the defaults if the student never saved anything.
  Stream<ReminderPreferences> watch() =>
      _doc.snapshots().map(ReminderPreferences.fromFirestore);

  /// READ (once).
  Future<ReminderPreferences> load() async =>
      ReminderPreferences.fromFirestore(await _doc.get());

  /// CREATE / UPDATE.
  Future<void> save(ReminderPreferences preferences) =>
      _doc.set(preferences.toFirestore());

  /// DELETE: removes saved settings, so the defaults apply again.
  Future<void> reset() => _doc.delete();
}
