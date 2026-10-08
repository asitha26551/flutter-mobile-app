import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/counselor_models.dart';
import '../models/student_model.dart';
import 'appointment_service.dart';
import 'student_service.dart';

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
    return CounselorProfile(
      user: user.data() ?? const {},
      details: details.data() ?? const {},
    );
  }

  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? department,
    String? professionalRole,
    String? professionalBio,
    String? officeLocation,
  }) async {
    final batch = _firestore.batch();
    final userData = <String, dynamic>{
      'fullName': fullName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (phoneNumber != null) {
      userData['phoneNumber'] = phoneNumber.trim();
    }
    batch.update(_firestore.collection('users').doc(uid), userData);

    final counselorData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (department != null) counselorData['department'] = department.trim();
    if (professionalRole != null) {
      counselorData['professionalRole'] = professionalRole.trim();
    }
    if (professionalBio != null) {
      counselorData['professionalBio'] = professionalBio.trim();
    }
    if (officeLocation != null) {
      counselorData['officeLocation'] = officeLocation.trim();
    }
    if (counselorData.length > 1) {
      batch.update(_firestore.collection('counselors').doc(uid), counselorData);
    }
    await batch.commit();
  }

  Stream<List<CounselorAppointment>> appointments() => _firestore
      .collection('appointments')
      .where('counselorId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final items = <CounselorAppointment>[];
        final studentService = StudentService(
          firestore: _firestore,
          auth: _auth,
        );
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          final studentId =
              (data['studentId'] as String?) ??
              (data['userId'] as String?) ??
              '';
          if (studentId.isNotEmpty) {
            try {
              final resolved = await studentService.resolveIdentity(studentId);
              final student =
                  resolved['student'] as StudentModel? ??
                  StudentModel(uid: studentId);
              final fullName = (resolved['fullName'] as String?) ?? '';
              final displayName = student.counselorDisplayName(
                fullName: fullName,
              );
              data['studentAlias'] = displayName;
              data['studentIdentity'] = displayName;
              data['studentFullName'] = fullName;
            } catch (_) {
              final student = StudentModel(uid: studentId);
              data['studentAlias'] = student.counselorDisplayName();
              data['studentIdentity'] = student.counselorDisplayName();
            }
          }
          items.add(CounselorAppointment(id: doc.id, data: data));
        }
        return items;
      });

  Future<void> updateAppointment(String id, String status) async {
    if (status == 'confirmed') {
      final appointmentService = AppointmentService(
        firestore: _firestore,
        auth: _auth,
      );
      await appointmentService.confirmAppointment(id);
      return;
    }

    if (status == 'rejected') {
      throw ArgumentError(
        'Reject appointments with a required reason through AppointmentService.reject.',
      );
    }

    await _firestore.collection('appointments').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() => _firestore
      .collection('conversations')
      .where('counselorId', isEqualTo: uid)
      .snapshots();
}
