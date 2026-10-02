import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createStudentProfile({
    required String uid,
    required String fullName,
    required String email,
    required Map<String, dynamic> studentData,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_users.doc(uid), {
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'role': 'student',
      'accountStatus': 'active',
      'verificationStatus': null,
      'profileImageUrl': null,
      'phoneNumber': studentData['phoneNumber'],
      'whatsappNumber': studentData['whatsappNumber'],
      'createdAt': now,
      'updatedAt': now,
      'emailVerified': false,
    });
    batch.set(_firestore.collection('students').doc(uid), {
      ...studentData,
      'uid': uid,
      'createdAt': now,
      'updatedAt': now,
    });
    await batch.commit();
  }

  Future<void> createCounselorProfile({
    required String uid,
    required String fullName,
    required String email,
    required Map<String, dynamic> counselorData,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(_users.doc(uid), {
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'role': 'counselor',
      'accountStatus': 'pending',
      'verificationStatus': 'pending',
      'profileImageUrl': null,
      'phoneNumber': counselorData['phoneNumber'],
      'whatsappNumber': counselorData['whatsappNumber'],
      'createdAt': now,
      'updatedAt': now,
      'emailVerified': false,
    });
    batch.set(_firestore.collection('counselors').doc(uid), {
      ...counselorData,
      'uid': uid,
      'accountStatus': 'pending',
      'verificationStatus': 'pending',
      'approvedAt': null,
      'approvedBy': null,
      'rejectedAt': null,
      'rejectedBy': null,
      'rejectionReason': null,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(_firestore.collection('counselor_public').doc(uid), {
      'uid': uid,
      'fullName': fullName.trim(),
      'profileImage': null,
      'department': counselorData['department'],
      'professionalRole': counselorData['professionalRole'],
      'specializations': counselorData['specializations'] ?? const <String>[],
      'yearsOfExperience': counselorData['yearsOfExperience'],
      'professionalBio': counselorData['professionalBio'],
      'languages': counselorData['languages'] ?? const <String>[],
      'sessionTypes': counselorData['sessionTypes'] ?? const <String>[],
      'officeLocation': counselorData['officeLocation'],
      'verificationStatus': 'pending',
      'accountStatus': 'pending',
      'createdAt': now,
      'updatedAt': now,
    });
    await batch.commit();
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
