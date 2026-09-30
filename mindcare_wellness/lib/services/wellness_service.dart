import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WellnessService {
  WellnessService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user.uid;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> availableCounselors() =>
      _firestore
          .collection('counselor_public')
          .where('verificationStatus', isEqualTo: 'approved')
          .where('accountStatus', isEqualTo: 'active')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> availability(
    String counselorId,
  ) => _firestore
      .collection('counselor_availability')
      .where('counselorId', isEqualTo: counselorId)
      .where('isAvailable', isEqualTo: true)
      .snapshots();

  Future<DocumentReference<Map<String, dynamic>>> createAvailability({
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
    return reference;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> studentAppointments() =>
      _firestore
          .collection('appointments')
          .where('studentId', isEqualTo: uid)
          .snapshots();

  Future<DocumentReference<Map<String, dynamic>>> createAppointment({
    required String counselorId,
    required DateTime startAt,
    required DateTime endAt,
    required String sessionType,
    String? reason,
    String? studentNotes,
    String? location,
  }) async {
    final reference = _firestore.collection('appointments').doc();
    await reference.set({
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
    return reference;
  }

  Future<void> cancelAppointment(String appointmentId, String reason) =>
      _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() => _firestore
      .collection('conversations')
      .where('studentId', isEqualTo: uid)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String conversationId) =>
      _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('sentAt')
          .snapshots();

  Future<DocumentReference<Map<String, dynamic>>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    final reference = _firestore.collection('messages').doc();
    await reference.set({
      'conversationId': conversationId,
      'senderId': uid,
      'receiverId': receiverId,
      'messageType': messageType,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });
    return reference;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notifications() => _firestore
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> markNotificationRead(String notificationId) =>
      _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

  Stream<QuerySnapshot<Map<String, dynamic>>> moodEntries() => _firestore
      .collection('mood_entries')
      .where('studentId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<DocumentReference<Map<String, dynamic>>> addMoodEntry({
    required String mood,
    required int moodScore,
    String? note,
  }) async {
    final reference = _firestore.collection('mood_entries').doc();
    await reference.set({
      'studentId': uid,
      'mood': mood,
      'moodScore': moodScore,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> journalEntries() => _firestore
      .collection('journal_entries')
      .where('studentId', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots();

  Future<DocumentReference<Map<String, dynamic>>> addJournalEntry({
    required String title,
    required String content,
    String? mood,
  }) async {
    final reference = _firestore.collection('journal_entries').doc();
    final now = FieldValue.serverTimestamp();
    await reference.set({
      'studentId': uid,
      'title': title,
      'content': content,
      'mood': mood,
      'createdAt': now,
      'updatedAt': now,
    });
    return reference;
  }

  Future<void> updateJournalEntry(
    String entryId, {
    required String title,
    required String content,
    String? mood,
  }) => _firestore.collection('journal_entries').doc(entryId).update({
    'title': title,
    'content': content,
    'mood': mood,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<DocumentReference<Map<String, dynamic>>> addSessionNote({
    required String appointmentId,
    required String studentId,
    required String summary,
    required String observations,
    required String followUpPlan,
  }) async {
    final reference = _firestore.collection('session_notes').doc();
    final now = FieldValue.serverTimestamp();
    await reference.set({
      'appointmentId': appointmentId,
      'studentId': studentId,
      'counselorId': uid,
      'summary': summary,
      'observations': observations,
      'followUpPlan': followUpPlan,
      'createdAt': now,
      'updatedAt': now,
    });
    return reference;
  }
}
