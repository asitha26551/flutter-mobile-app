import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? firestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Timestamp? firestoreTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);
