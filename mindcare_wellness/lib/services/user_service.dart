import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> createClientProfile({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _users.doc(uid).set({
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'client',
      'profileImage': null,
      'phoneNumber': null,
      'createdAt': now,
      'updatedAt': now,
      'emailVerified': false,
    });
  }

  Future<AppUser?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }

  Future<void> markEmailVerified(String uid) async {
    await _users.doc(uid).update({
      'emailVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
