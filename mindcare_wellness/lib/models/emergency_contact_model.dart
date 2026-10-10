import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converters.dart';

/// A personal emergency contact added by the student.
/// Stored at: users/{uid}/emergency_contacts/{contactId}
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final DateTime? createdAt;

  factory EmergencyContact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return EmergencyContact(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      createdAt: firestoreDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phoneNumber': phoneNumber,
    'relationship': relationship,
    'createdAt': firestoreTimestamp(createdAt) ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
