import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_contact_model.dart';

/// Personal emergency contacts: full CRUD.
class EmergencyService {
  EmergencyService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('users').doc(uid).collection('emergency_contacts');

  /// READ (live), oldest first.
  Stream<List<EmergencyContact>> mine() => _contacts
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(EmergencyContact.fromFirestore).toList());

  /// CREATE.
  Future<void> add({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) => _contacts.add(
    EmergencyContact(
      id: '',
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      relationship: relationship.trim(),
    ).toFirestore(),
  );

  /// UPDATE (createdAt is left untouched).
  Future<void> update(EmergencyContact contact) =>
      _contacts.doc(contact.id).update({
        'name': contact.name.trim(),
        'phoneNumber': contact.phoneNumber.trim(),
        'relationship': contact.relationship.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// DELETE.
  Future<void> delete(String contactId) => _contacts.doc(contactId).delete();
}
