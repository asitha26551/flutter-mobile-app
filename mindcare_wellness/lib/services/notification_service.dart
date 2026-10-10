import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('You must be signed in.'));

  Stream<List<NotificationModel>> mine() => _firestore
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(NotificationModel.fromFirestore).toList());

  Future<void> markRead(String notificationId) =>
      _firestore.collection('notifications').doc(notificationId).update({'isRead': true});

  Future<void> markAllRead() async {
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final notification in unread.docs) {
      batch.update(notification.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> delete(String notificationId) =>
      _firestore.collection('notifications').doc(notificationId).delete();
}
