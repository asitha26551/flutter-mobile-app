import 'package:cloud_firestore/cloud_firestore.dart';

class CounselorProfile {
  const CounselorProfile({required this.user, required this.details});

  final Map<String, dynamic> user;
  final Map<String, dynamic> details;

  String get name => user['fullName'] as String? ?? 'Counselor';
  String get department =>
      details['department'] as String? ?? 'University Counseling Unit';
  String get professionalRole =>
      details['professionalRole'] as String? ?? 'University Counselor';
  String? get imageUrl =>
      user['profileImageUrl'] as String? ?? user['profileImage'] as String?;
}

class CounselorAppointment {
  const CounselorAppointment({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get status => data['status'] as String? ?? 'pending';
  String get studentId =>
      data['studentId'] as String? ?? data['userId'] as String? ?? '';
  String get counselorId => data['counselorId'] as String? ?? '';
  String get sessionType =>
      data['sessionType'] as String? ??
      data['type'] as String? ??
      'Counseling session';
  String get reason => data['reason'] as String? ?? 'Counseling session';
  String? get location => data['location'] as String?;
  String? get meetingLink => data['meetingLink'] as String?;
  String? get mood =>
      data['mood'] as String? ?? data['studentMood'] as String?;
  int? get moodScore =>
      (data['moodScore'] as num?)?.toInt() ??
      (data['studentMoodScore'] as num?)?.toInt();
  String get studentAlias =>
      data['studentAlias'] as String? ??
      data['anonymousId'] as String? ??
      (studentId.isEmpty
          ? 'Anonymous student'
          : 'Student #${studentId.length > 6 ? studentId.substring(0, 6) : studentId}');
  DateTime? get startAt => _date(data['startAt'] ?? data['appointmentDate']);
  DateTime? get endAt => _date(data['endAt']);
  String? get rejectionReason => data['rejectionReason'] as String?;
  String? get cancellationReason => data['cancellationReason'] as String?;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
