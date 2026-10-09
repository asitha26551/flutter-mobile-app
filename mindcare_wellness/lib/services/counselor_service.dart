import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/counselor_models.dart';

class CounselorService {
  CounselorService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser!.uid;

  Future<CounselorProfile> getProfile() async {
    final user = await _firestore.collection('users').doc(uid).get();
    final details = await _firestore.collection('counselors').doc(uid).get();
    return CounselorProfile(user: user.data() ?? const {}, details: details.data() ?? const {});
  }

  Stream<List<CounselorAppointment>> appointments() => _firestore
      .collection('appointments')
      .where('counselorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CounselorAppointment(id: doc.id, data: doc.data())).toList());

  Future<void> updateAppointment(String id, String status) => _firestore.collection('appointments').doc(id).update({
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() => _firestore
      .collection('conversations')
      .where('counselorId', isEqualTo: uid)
      .snapshots();
}