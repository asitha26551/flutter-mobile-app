import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_model.dart';

class StudentService {
  StudentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Future<StudentModel?> get(String studentId) async {
    final snapshot = await _firestore
        .collection('students')
        .doc(studentId)
        .get();
    return snapshot.exists ? StudentModel.fromFirestore(snapshot) : null;
  }

  Future<Map<String, dynamic>> resolveIdentity(String studentId) async {
    final student = await get(studentId) ?? StudentModel(uid: studentId);
    final userSnapshot = await _firestore.collection('users').doc(studentId).get();
    final fullName = (userSnapshot.data()?['fullName'] as String?)?.trim() ?? '';
    return {
      'student': student,
      'fullName': fullName,
      'displayName': student.counselorDisplayName(fullName: fullName),
      'searchText': [student.alias ?? '', fullName].join(' '),
    };
  }

  Future<StudentModel?> mine() => get(uid);

  Future<void> updatePriority({
    required String studentId,
    required String priorityLevel,
  }) async {
    if (priorityLevel != 'normal' && priorityLevel != 'high') {
      throw ArgumentError('Unsupported priority level.');
    }
    await _firestore.collection('students').doc(studentId).update({
      'priorityLevel': priorityLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
