import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? firestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}

Timestamp? firestoreTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
