import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/appointment_model.dart';

class AppointmentService {
  AppointmentService({FirebaseFirestore? firestore, FirebaseAuth? auth, String? backendBaseUrl})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _backendBaseUrl = backendBaseUrl ?? 'http://localhost:3000';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _backendBaseUrl;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<AppointmentModel>> forStudent() => _query('studentId', uid);
  Stream<List<AppointmentModel>> forCounselor() => _query('counselorId', uid);

  Stream<List<AppointmentModel>> _query(String field, String value) =>
      _firestore
          .collection('appointments')
          .where(field, isEqualTo: value)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(AppointmentModel.fromFirestore).toList(),
          );

  Future<String> create({
    required String counselorId,
    required DateTime startAt,
    required DateTime endAt,
    required String sessionType,
    String? reason,
    String? location,
    String? studentNotes,
  }) async {
    final reference = _firestore.collection('appointments').doc();
    final batch = _firestore.batch();
    batch.set(reference, {
      'studentId': uid,
      'counselorId': counselorId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'sessionType': sessionType,
      'status': 'pending',
      'reason': reason,
      'meetingLink': null,
      'location': location,
      'studentNotes': studentNotes,
      'cancellationReason': null,
      'cancelledBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('students').doc(uid), {
      'authorizedCounselorIds': FieldValue.arrayUnion([counselorId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return reference.id;
  }

  Future<void> confirmAppointment(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final token = await user.getIdToken();
    final uri = Uri.parse('$_backendBaseUrl/appointments/$id/confirm');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to confirm appointment. ${response.body}');
    }
  }

  Future<void> accept(String id) => confirmAppointment(id);
  Future<void> reject(String id) => _updateCounselorStatus(id, 'rejected');
  Future<void> complete(String id) => _updateCounselorStatus(id, 'completed');
  Future<void> markNoShow(String id) => _updateCounselorStatus(id, 'no_show');

  Future<void> updateCounselorStatus(String id, String status) async {
    if (status == 'confirmed') {
      await confirmAppointment(id);
      return;
    }
    await _updateCounselorStatus(id, status);
  }

  Future<void> _updateCounselorStatus(String id, String status) => _firestore
      .collection('appointments')
      .doc(id)
      .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> cancel(String id, {required String reason}) =>
      _firestore.collection('appointments').doc(id).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> reschedule(
    String id, {
    required DateTime startAt,
    required DateTime endAt,
  }) {
    if (!endAt.isAfter(startAt)) {
      throw ArgumentError(
        'The appointment end time must be after its start time.',
      );
    }
    return _firestore.collection('appointments').doc(id).update({
      'status': 'rescheduled',
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
