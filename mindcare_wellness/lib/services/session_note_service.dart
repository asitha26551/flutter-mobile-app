import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_note_model.dart';
import '../models/appointment_model.dart';

class SessionNoteEntry {
  const SessionNoteEntry({required this.note, this.appointment});

  final SessionNoteModel note;
  final AppointmentModel? appointment;

  String get studentLabel {
    final studentId = appointment?.studentId ?? note.studentId;
    return appointment?.studentId.isNotEmpty == true
        ? 'Student #${studentId.length > 6 ? studentId.substring(0, 6) : studentId}'
        : 'Anonymous student';
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

  Stream<List<SessionNoteModel>> forStudent(String studentId) => _firestore
      .collection('session_notes')
      .where('counselorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map(SessionNoteModel.fromFirestore)
          .where((note) => note.studentId == studentId)
          .toList());

  Future<List<SessionNoteEntry>> loadEntries(List<SessionNoteModel> notes) async {
    final entries = await Future.wait(notes.map((note) async {
      final appointment = await _firestore
          .collection('appointments')
          .doc(note.appointmentId)
          .get();
      return SessionNoteEntry(
        note: note,
        appointment: appointment.exists
            ? AppointmentModel.fromFirestore(appointment)
            : null,
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
