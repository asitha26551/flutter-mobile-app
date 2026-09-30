import 'package:cloud_firestore/cloud_firestore.dart';

class CounselorProfile {
  const CounselorProfile({required this.user, required this.details});

  final Map<String, dynamic> user;
  final Map<String, dynamic> details;

  String get name => user['fullName'] as String? ?? 'Counselor';
  String get department => details['department'] as String? ?? 'University Counseling Unit';
  String get professionalRole => details['professionalRole'] as String? ?? 'University Counselor';
  String? get imageUrl => user['profileImageUrl'] as String? ?? user['profileImage'] as String?;
}

class CounselorAppointment {
  const CounselorAppointment({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get status => data['status'] as String? ?? 'pending';
  String get studentId => data['studentId'] as String? ?? data['userId'] as String? ?? '';
  String get sessionType => data['sessionType'] as String? ?? data['type'] as String? ?? 'Counseling session';
  DateTime? get startAt => _date(data['startAt'] ?? data['appointmentDate']);

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}