import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/appointment_model.dart';

class AppointmentService {
  AppointmentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? backendBaseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _backendBaseUrl = (backendBaseUrl ?? _defaultBackendBaseUrl)
           .replaceFirst(RegExp(r'/+$'), '');

  static const _configuredBackendBaseUrl = String.fromEnvironment(
    'MINDCARE_API_BASE_URL',
  );

  static String get _defaultBackendBaseUrl {
    if (_configuredBackendBaseUrl.isNotEmpty) return _configuredBackendBaseUrl;
    // Android emulators reach the host machine through this bridge address.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

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
    String? studentAlias,
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
      'studentAlias': studentAlias?.trim(),
      'cancellationReason': null,
      'cancelledBy': null,
      'rejectionReason': null,
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

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user.getIdToken();
  }

  Future<void> confirmAppointment(String id) async {
    final token = await _getToken();
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

  /// Reject an appointment through the trusted backend.
  /// [reason] must be a non-empty trimmed string.
  Future<void> reject(String id, {required String reason}) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('A rejection reason is required.');
    }
    final token = await _getToken();
    final uri = Uri.parse('$_backendBaseUrl/appointments/$id/reject');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rejectionReason': trimmed}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Unable to reject appointment. ${response.body}');
    }
  }

  Future<void> complete(String id) => _updateCounselorStatus(id, 'completed');
  Future<void> markNoShow(String id) => _updateCounselorStatus(id, 'no_show');

  Future<void> updateCounselorStatus(String id, String status) async {
    if (status == 'confirmed') {
      await confirmAppointment(id);
      return;
    }
    if (status == 'rejected') {
      throw ArgumentError(
        'A rejection reason is required; call reject with the reason.',
      );
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

  Future<void> withdrawPending(String id) async {
    final reference = _firestore.collection('appointments').doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This appointment request no longer exists.');
      }
      final status = (snapshot.data()?['status'] as String? ?? '').toLowerCase();
      if (status != 'pending') {
        throw StateError('Only an unconfirmed request can be withdrawn.');
      }
      transaction.update(reference, {
        'status': 'cancelled',
        'cancellationReason': 'Withdrawn by student',
        'cancelledBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Reschedule an appointment through the trusted backend.
  /// The backend handles Zoom meeting updates for video appointments.
  Future<void> reschedule(
    String id, {
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    if (!endAt.isAfter(startAt)) {
      throw ArgumentError(
        'The appointment end time must be after its start time.',
      );
    }
    final token = await _getToken();
    final uri = Uri.parse('$_backendBaseUrl/appointments/$id/reschedule');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Unable to reschedule appointment. ${response.body}');
    }
  }

  /// Retrieve the host/start URL for a video appointment from the trusted backend.
  /// Only counselors who own the appointment may call this.
  Future<String> getHostLink(String appointmentId) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '$_backendBaseUrl/appointments/$appointmentId/host-link',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('Unable to retrieve host link. ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final startUrl = body['startUrl'] as String?;
    if (startUrl == null || startUrl.isEmpty) {
      throw Exception('Host link not available.');
    }
    return startUrl;
  }
}
