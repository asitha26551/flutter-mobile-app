import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a counseling appointment/booking session in MindCare Wellness.
@immutable
class BookingModel {
  const BookingModel({
    required this.bookingId,
    required this.counselorId,
    required this.counselorName,
    required this.sessionFormat,
    required this.date,
    required this.timeSlot,
    this.studentId = '',
    this.pseudonym = '',
    this.passcode = '',
    this.reason = '',
    this.isAnonymousMode = false,
    this.status = 'Confirmed',
    this.privacySettings,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier of the booking record.
  final String bookingId;

  /// Identifier of the student (optional/masked when [isAnonymousMode] is true).
  final String studentId;

  /// Identifier of the selected counselor.
  final String counselorId;

  /// Display name of the selected counselor.
  final String counselorName;

  /// Format of the counseling session (e.g. "Online Video", "In-Person", "Confidential Chat").
  final String sessionFormat;

  /// Scheduled date of the appointment.
  final DateTime date;

  /// Scheduled time window (e.g. "10:00 AM - 11:00 AM").
  final String timeSlot;

  /// Anonymous pseudonym chosen for this booking if booked under confidential mode.
  final String pseudonym;

  /// Security passcode assigned/required to access this specific confidential session.
  final String passcode;

  /// Student's reason or focus topic for the session.
  final String reason;

  /// Flag indicating whether the booking was made under anonymous/confidential mode.
  final bool isAnonymousMode;

  /// Current status of the appointment: "Confirmed", "Upcoming", "Completed", "Cancelled".
  final String status;

  /// Optional snapshot of student privacy settings associated with this booking.
  final Map<String, dynamic>? privacySettings;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last modification timestamp.
  final DateTime? updatedAt;

  // --- Convenience Getters & Aliases ---

  /// Alias for [isAnonymousMode] complying with specification.
  bool get isAnonymous => isAnonymousMode;

  /// Alias for [date] complying with specification.
  DateTime get bookingDate => date;

  /// Checks if this session is active/upcoming.
  bool get isUpcoming =>
      (status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'confirmed') &&
      !isCancelled;

  /// Checks if this session is pending confirmation.
  bool get isPending => status.toLowerCase() == 'pending';

  /// Checks if this session has been cancelled.
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Checks if this session is completed or past.
  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'past';

  /// Alias for past sessions.
  bool get isPast => isCompleted;

  /// Alias for session reason/notes.
  String get sessionNotes => reason;

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return null;
  }

  /// Creates a [BookingModel] from a JSON map with strict null-safety and robust date parsing.
  factory BookingModel.fromJson(
    Map<String, dynamic>? json, {
    String? bookingId,
  }) {
    if (json == null) {
      return BookingModel(
        bookingId: bookingId ?? '',
        counselorId: '',
        counselorName: '',
        sessionFormat: 'Online Video',
        date: DateTime.now(),
        timeSlot: '',
        studentId: '',
        pseudonym: '',
        passcode: '',
        reason: '',
        isAnonymousMode: false,
        status: 'Confirmed',
      );
    }

    final rawDate = json['date'] ?? json['bookingDate'] ?? json['appointmentDate'];
    final parsedDate = _parseDateTime(rawDate);
    final parsedCreatedAt = _parseNullableDateTime(json['createdAt']);
    final parsedUpdatedAt = _parseNullableDateTime(json['updatedAt']);

    final isAnon = json['isAnonymousMode'] as bool? ??
        json['isAnonymous'] as bool? ??
        false;

    return BookingModel(
      bookingId: bookingId ??
          (json['bookingId'] as String? ?? json['id'] as String? ?? ''),
      studentId: json['studentId'] as String? ?? '',
      counselorId: json['counselorId'] as String? ?? '',
      counselorName: json['counselorName'] as String? ?? '',
      sessionFormat: json['sessionFormat'] as String? ??
          (json['sessionType'] as String? ?? 'Online Video'),
      date: parsedDate,
      timeSlot: json['timeSlot'] as String? ??
          (json['startTime'] as String? ?? ''),
      pseudonym: json['pseudonym'] as String? ?? '',
      passcode: json['passcode'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      isAnonymousMode: isAnon,
      status: json['status'] as String? ?? 'Confirmed',
      privacySettings: json['privacySettings'] is Map<String, dynamic>
          ? json['privacySettings'] as Map<String, dynamic>
          : null,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Creates a [BookingModel] from a Cloud Firestore [DocumentSnapshot].
  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return BookingModel.fromJson(snapshot.data(), bookingId: snapshot.id);
  }

  /// Serializes the model into a standard JSON map with ISO-8601 string date.
  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'studentId': studentId,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'sessionFormat': sessionFormat,
      'date': date.toIso8601String(),
      'bookingDate': date.toIso8601String(),
      'timeSlot': timeSlot,
      'pseudonym': pseudonym,
      'passcode': passcode,
      'reason': reason,
      'isAnonymousMode': isAnonymousMode,
      'isAnonymous': isAnonymousMode,
      'status': status,
      if (privacySettings != null) 'privacySettings': privacySettings,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Serializes the model into a Firestore-compatible document data map with [Timestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'studentId': studentId,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'sessionFormat': sessionFormat,
      'date': Timestamp.fromDate(date),
      'bookingDate': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'pseudonym': pseudonym,
      'passcode': passcode,
      'reason': reason,
      'isAnonymousMode': isAnonymousMode,
      'isAnonymous': isAnonymousMode,
      'status': status,
      if (privacySettings != null) 'privacySettings': privacySettings,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Returns an updated copy with modified fields.
  BookingModel copyWith({
    String? bookingId,
    String? studentId,
    String? counselorId,
    String? counselorName,
    String? sessionFormat,
    DateTime? date,
    String? timeSlot,
    String? pseudonym,
    String? passcode,
    String? reason,
    bool? isAnonymousMode,
    String? status,
    Map<String, dynamic>? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      studentId: studentId ?? this.studentId,
      counselorId: counselorId ?? this.counselorId,
      counselorName: counselorName ?? this.counselorName,
      sessionFormat: sessionFormat ?? this.sessionFormat,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      pseudonym: pseudonym ?? this.pseudonym,
      passcode: passcode ?? this.passcode,
      reason: reason ?? this.reason,
      isAnonymousMode: isAnonymousMode ?? this.isAnonymousMode,
      status: status ?? this.status,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          bookingId == other.bookingId &&
          studentId == other.studentId &&
          counselorId == other.counselorId &&
          counselorName == other.counselorName &&
          sessionFormat == other.sessionFormat &&
          date == other.date &&
          timeSlot == other.timeSlot &&
          pseudonym == other.pseudonym &&
          passcode == other.passcode &&
          reason == other.reason &&
          isAnonymousMode == other.isAnonymousMode &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        bookingId,
        studentId,
        counselorId,
        counselorName,
        sessionFormat,
        date,
        timeSlot,
        pseudonym,
        passcode,
        reason,
        isAnonymousMode,
        status,
      );

  @override
  String toString() {
    return 'BookingModel('
        'bookingId: $bookingId, '
        'studentId: $studentId, '
        'counselorId: $counselorId, '
        'counselorName: $counselorName, '
        'sessionFormat: $sessionFormat, '
        'date: $date, '
        'timeSlot: $timeSlot, '
        'pseudonym: $pseudonym, '
        'passcode: ${passcode.isNotEmpty ? '***' : ''}, '
        'reason: $reason, '
        'isAnonymousMode: $isAnonymousMode, '
        'status: $status)';
  }
}
