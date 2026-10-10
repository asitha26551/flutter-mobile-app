import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

/// A student's reminder settings (channels, lead time, quiet hours).
/// Stored as ONE document: users/{uid}/settings/reminder_preferences
class ReminderPreferences {
  const ReminderPreferences({
    this.whatsapp = true,
    this.sms = true,
    this.email = false,
    this.push = true,
    this.remindBeforeMinutes = 60, // 15, 60 or 1440 (1 day)
    this.quietHoursEnabled = true,
    this.quietStart = '22:00', // 24h "HH:mm"
    this.quietEnd = '08:00',
    this.updatedAt,
  });

  final bool whatsapp;
  final bool sms;
  final bool email;
  final bool push;
  final int remindBeforeMinutes;
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;
  final DateTime? updatedAt;

  /// Missing document or missing fields fall back to the defaults above.
  factory ReminderPreferences.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    const d = ReminderPreferences();
    return ReminderPreferences(
      whatsapp: data['whatsapp'] as bool? ?? d.whatsapp,
      sms: data['sms'] as bool? ?? d.sms,
      email: data['email'] as bool? ?? d.email,
      push: data['push'] as bool? ?? d.push,
      remindBeforeMinutes:
          (data['remindBeforeMinutes'] as num?)?.toInt() ?? d.remindBeforeMinutes,
      quietHoursEnabled:
          data['quietHoursEnabled'] as bool? ?? d.quietHoursEnabled,
      quietStart: data['quietStart'] as String? ?? d.quietStart,
      quietEnd: data['quietEnd'] as String? ?? d.quietEnd,
      updatedAt: firestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'whatsapp': whatsapp,
    'sms': sms,
    'email': email,
    'push': push,
    'remindBeforeMinutes': remindBeforeMinutes,
    'quietHoursEnabled': quietHoursEnabled,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  ReminderPreferences copyWith({
    bool? whatsapp,
    bool? sms,
    bool? email,
    bool? push,
    int? remindBeforeMinutes,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
  }) => ReminderPreferences(
    whatsapp: whatsapp ?? this.whatsapp,
    sms: sms ?? this.sms,
    email: email ?? this.email,
    push: push ?? this.push,
    remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    updatedAt: updatedAt,
  );
}
