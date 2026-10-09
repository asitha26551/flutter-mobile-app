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
    final studentFuture = _firestore.collection('students').doc(studentId).get();
    final userFuture = _firestore
        .collection('users')
        .doc(studentId)
        .get()
        .then((snapshot) => snapshot, onError: (Object _) => null);
    final studentSnapshot = await studentFuture;
    final student = studentSnapshot.exists
        ? StudentModel.fromFirestore(studentSnapshot)
        : StudentModel(uid: studentId);
    String fullName = '';

    final userSnapshot = await userFuture;
    fullName = (userSnapshot.data()?['fullName'] as String?)?.trim() ?? '';

    return {
      'student': student,
      'fullName': fullName,
      'displayName': student.counselorDisplayName(fullName: fullName),
      'searchText': [student.alias ?? '', fullName].join(' '),
    };
  }

  Future<StudentModel?> mine() => get(uid);

  Future<void> updateAnonymousMode({
    required String studentId,
    required bool isAnonymous,
  }) async {
    await _firestore.collection('students').doc(studentId).update({
      'isAnonymous': isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudent({
    required String studentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('students').doc(studentId).update(data);
  }

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
