import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';
import 'notification_service.dart';

/// Adds the operations the group's NotificationService does not have
/// (delete, mark all read, clear all, create). It reuses their mine() and
/// markRead(), so their file is NOT edited.
class StudentNotificationService {
  StudentNotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? base,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _base = base ?? NotificationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _base;

  String get uid =>
      _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  /// READ (live), newest first.
  Stream<List<NotificationModel>> mine() => _base.mine();

  /// UPDATE: mark one notification as read.
  Future<void> markRead(String id) => _base.markRead(id);

  /// UPDATE: mark every unread notification as read.
  Future<void> markAllRead() async {
    final unread = await _col
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// DELETE one notification.
  Future<void> delete(String id) => _col.doc(id).delete();

  /// DELETE all of the student's notifications (the "CLEAR" button).
  Future<void> clearAll() async {
    final all = await _col.where('userId', isEqualTo: uid).get();
    if (all.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in all.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  /// CREATE: e.g. when a reminder fires or settings are saved.
  Future<void> create({
    required String title,
    required String body,
    String type = 'reminder',
    String? relatedId,
  }) => _col.add(
    NotificationModel(
      id: '',
      userId: uid,
      title: title,
      body: body,
      type: type,
      isRead: false,
      relatedId: relatedId,
    ).toFirestore(),
  );
}
