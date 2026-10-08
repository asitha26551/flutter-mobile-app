import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/counselor_availability_model.dart';

class AvailabilityService {
  AvailabilityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<CounselorAvailabilityModel>> forCounselor(String counselorId) =>
      _firestore
          .collection('counselor_availability')
          .where('counselorId', isEqualTo: counselorId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(CounselorAvailabilityModel.fromFirestore).toList());

  Stream<List<CounselorAvailabilityModel>> availableForBooking(String counselorId) =>
      _firestore
          .collection('counselor_availability')
          .where('counselorId', isEqualTo: counselorId)
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(CounselorAvailabilityModel.fromFirestore).toList());

  Future<String> create({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    required int sessionDuration,
    bool isAvailable = true,
  }) async {
    final reference = _firestore.collection('counselor_availability').doc();
    await reference.set({
      'counselorId': uid,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'sessionDuration': sessionDuration,
      'isAvailable': isAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> update(String id, Map<String, dynamic> changes) =>
      _firestore.collection('counselor_availability').doc(id).update({
        ...changes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) =>
      _firestore.collection('counselor_availability').doc(id).delete();
}
