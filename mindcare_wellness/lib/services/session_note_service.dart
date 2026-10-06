import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_note_model.dart';
import '../models/appointment_model.dart';
import '../models/student_model.dart';

class SessionNoteEntry {
  const SessionNoteEntry({
    required this.note,
    this.appointment,
    this.displayName = '',
    this.alias,
    this.fullName,
  });

  final SessionNoteModel note;
  final AppointmentModel? appointment;
  final String displayName;
  final String? alias;
  final String? fullName;

  String get studentLabel {
    if (displayName.trim().isNotEmpty) return displayName;
    return appointment?.studentId.isNotEmpty == true ? 'Student' : 'Anonymous student';
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final aliasValue = alias?.trim() ?? '';
    final fullNameValue = fullName?.trim() ?? '';
    final combined = [aliasValue, fullNameValue, displayName].join(' ').toLowerCase();
    return combined.contains(normalizedQuery);
  }
}

class SessionNoteService {
  SessionNoteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<SessionNoteModel>> forCounselor() => _firestore
      .collection('session_notes')
      .where('counselorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final notes = snapshot.docs.map(SessionNoteModel.fromFirestore).toList();
        notes.sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
        return notes;
      });

  Stream<List<SessionNoteModel>> forAppointment(String appointmentId) =>
      _firestore
          .collection('session_notes')
          .where('counselorId', isEqualTo: uid)
          .snapshots()
        .map((snapshot) => snapshot.docs
          .map(SessionNoteModel.fromFirestore)
          .where((note) => note.appointmentId == appointmentId)
          .toList());

  Future<List<SessionNoteEntry>> loadEntries(List<SessionNoteModel> notes) async {
    final entries = await Future.wait(notes.map((note) async {
      final appointment = await _firestore
          .collection('appointments')
          .doc(note.appointmentId)
          .get();
      final appointmentModel = appointment.exists
          ? AppointmentModel.fromFirestore(appointment)
          : null;
      final studentId = appointmentModel?.studentId ?? note.studentId;
      StudentModel student = StudentModel(uid: studentId);

      if (studentId.isNotEmpty) {
        try {
          final studentSnapshot = await _firestore.collection('students').doc(studentId).get();
          if (studentSnapshot.exists) {
            student = StudentModel.fromFirestore(studentSnapshot);
          }
        } catch (_) {
          student = StudentModel(uid: studentId);
        }
      }

      String fullName = '';
      if (studentId.isNotEmpty) {
        try {
          final userSnapshot = await _firestore.collection('users').doc(studentId).get();
          fullName = (userSnapshot.data()?['fullName'] as String?)?.trim() ?? '';
        } catch (_) {
          fullName = '';
        }
      }

      final displayName = student.counselorDisplayName(fullName: fullName);

      return SessionNoteEntry(
        note: note,
        appointment: appointmentModel,
        displayName: displayName,
        alias: student.alias,
        fullName: fullName,
      );
    }));
    return entries;
  }

  Future<String> create({
    required String appointmentId,
    required String studentId,
    required String note,
  }) async {
    final reference = _firestore.collection('session_notes').doc();
    await reference.set({
      'appointmentId': appointmentId,
      'studentId': studentId,
      'counselorId': uid,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<void> update(
    String id, {
    required String note,
  }) => _firestore.collection('session_notes').doc(id).update({
    'note': note.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
