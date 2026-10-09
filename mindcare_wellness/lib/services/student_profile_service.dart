import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads and edits the signed-in student's contact details.
/// Writes only fields the group's Firestore rules already allow
/// (fullName, phoneNumber, whatsappNumber, updatedAt).
class StudentProfileService {
  StudentProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(uid);

  /// READ (live): the raw users/{uid} data.
  Stream<Map<String, dynamic>> watch() =>
      _userDoc.snapshots().map((s) => s.data() ?? const <String, dynamic>{});

  /// UPDATE: name and phone numbers (kept in sync in users and students).
  Future<void> update({
    required String fullName,
    required String phoneNumber,
    required String whatsappNumber,
  }) async {
    final now = FieldValue.serverTimestamp();
    final phone = phoneNumber.trim().isEmpty ? null : phoneNumber.trim();
    final whatsapp = whatsappNumber.trim().isEmpty
        ? null
        : whatsappNumber.trim();
    final batch = _firestore.batch();
    batch.update(_userDoc, {
      'fullName': fullName.trim(),
      'phoneNumber': phone,
      'whatsappNumber': whatsapp,
      'updatedAt': now,
    });
    batch.update(_firestore.collection('students').doc(uid), {
      'phoneNumber': phone,
      'whatsappNumber': whatsapp,
      'updatedAt': now,
    });
    await batch.commit();
  }
}
