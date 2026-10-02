import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_action_model.dart';

class AdminUserRecord {
  const AdminUserRecord({required this.data, this.roleData = const {}});

  final Map<String, dynamic> data;
  final Map<String, dynamic> roleData;

  String get uid => data['uid'] as String? ?? '';
  String get fullName => data['fullName'] as String? ?? 'Unnamed user';
  String get email => data['email'] as String? ?? '';
  String get role => data['role'] as String? ?? '';
  String get accountStatus => data['accountStatus'] as String? ?? 'active';
  String get verificationStatus => data['verificationStatus'] as String? ?? '';
  String get displayId => role == 'student'
      ? roleData['studentId'] as String? ?? '-'
      : roleData['staffId'] as String? ?? '-';

  String get status => accountStatus == 'suspended'
      ? 'suspended'
      : role == 'counselor' && verificationStatus.isNotEmpty
      ? verificationStatus
      : accountStatus;
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.students,
    required this.counselors,
    required this.pendingCounselors,
    required this.approvedCounselors,
    required this.rejectedCounselors,
    required this.suspendedUsers,
  });

  final int students;
  final int counselors;
  final int pendingCounselors;
  final int approvedCounselors;
  final int rejectedCounselors;
  final int suspendedUsers;
}

class AdminService {
  AdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<AdminActionModel>> auditActions() => _firestore
      .collection('admin_actions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(AdminActionModel.fromFirestore).toList(),
      );

  Future<List<AdminUserRecord>> getUsers({required String role}) async {
    await _ensureAdminClaim();
    final userSnapshot = await _users.where('role', isEqualTo: role).get();
    final records = <AdminUserRecord>[];
    for (final user in userSnapshot.docs) {
      final collection = role == 'student' ? 'students' : 'counselors';
      final roleSnapshot = await _firestore
          .collection(collection)
          .doc(user.id)
          .get();
      records.add(
        AdminUserRecord(
          data: user.data(),
          roleData: roleSnapshot.data() ?? const {},
        ),
      );
    }
    records.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return records;
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    await _ensureAdminClaim();
    final snapshot = await _users.get();
    var students = 0;
    var counselors = 0;
    var pending = 0;
    var approved = 0;
    var rejected = 0;
    var suspended = 0;
    for (final document in snapshot.docs) {
      final data = document.data();
      final role = data['role'];
      final accountStatus = data['accountStatus'];
      final verificationStatus = data['verificationStatus'];
      if (accountStatus == 'suspended') suspended++;
      if (role == 'student') students++;
      if (role == 'counselor') {
        counselors++;
        if (verificationStatus == 'pending') pending++;
        if (verificationStatus == 'approved') approved++;
        if (verificationStatus == 'rejected') rejected++;
      }
    }
    return AdminDashboardStats(
      students: students,
      counselors: counselors,
      pendingCounselors: pending,
      approvedCounselors: approved,
      rejectedCounselors: rejected,
      suspendedUsers: suspended,
    );
  }

  Future<void> approveCounselor(String uid) => _updateCounselor(
    uid,
    status: 'approved',
    accountStatus: 'active',
    fields: {
      'approvedBy': _adminUid,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectedBy': null,
      'rejectedAt': null,
      'rejectionReason': null,
    },
    action: 'approve_counselor',
  );

  Future<void> rejectCounselor(String uid, String reason) => _updateCounselor(
    uid,
    status: 'rejected',
    accountStatus: 'pending',
    fields: {
      'rejectedBy': _adminUid,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason.trim(),
      'approvedBy': null,
      'approvedAt': null,
    },
    action: 'reject_counselor',
  );

  Future<void> suspendUser(AdminUserRecord user) =>
      _updateStatus(
        user,
        'suspended',
        user.role == 'counselor' ? 'suspend_counselor' : 'suspend_student',
      );

  Future<void> reactivateUser(AdminUserRecord user) => _updateStatus(
    user,
    user.role == 'counselor' ? 'active' : 'active',
    user.role == 'counselor' ? 'reactivate_counselor' : 'reactivate_student',
  );

  String get _adminUid => _auth.currentUser?.uid ?? '';

  Future<void> _updateCounselor(
    String uid, {
    required String status,
    required String accountStatus,
    required Map<String, dynamic> fields,
    required String action,
  }) async {
    await _ensureAdminClaim();
    final batch = _firestore.batch();
    final userReference = _users.doc(uid);
    final counselorReference = _firestore.collection('counselors').doc(uid);
    final publicCounselorReference = _firestore
      .collection('counselor_public')
      .doc(uid);
    final now = FieldValue.serverTimestamp();
    batch.update(userReference, {
      'verificationStatus': status,
      'accountStatus': accountStatus,
      'updatedAt': now,
      ...fields,
    });
    batch.update(counselorReference, {
      'verificationStatus': status,
      'accountStatus': accountStatus,
      'updatedAt': now,
      ...fields,
    });
    batch.update(publicCounselorReference, {
      'verificationStatus': status,
      'accountStatus': accountStatus,
      'updatedAt': now,
    });
    _addAudit(
      batch,
      action,
      uid,
      'counselor',
      reason: fields['rejectionReason'] as String?,
    );
    await batch.commit();
  }

  Future<void> _updateStatus(
    AdminUserRecord user,
    String status,
    String action,
  ) async {
    await _ensureAdminClaim();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    batch.update(_users.doc(user.uid), {
      'accountStatus': status,
      'updatedAt': now,
    });
    final collection = user.role == 'student' ? 'students' : 'counselors';
    batch.update(_firestore.collection(collection).doc(user.uid), {
      'accountStatus': status,
      'updatedAt': now,
    });
    _addAudit(batch, action, user.uid, user.role);
    await batch.commit();
  }

  void _addAudit(
    WriteBatch batch,
    String action,
    String targetUserId,
    String targetRole, {
    String? reason,
  }) {
    batch.set(_firestore.collection('admin_actions').doc(), {
      'adminId': _adminUid,
      'action': action,
      'targetUserId': targetUserId,
      'targetRole': targetRole,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureAdminClaim() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in as an administrator.');
    }
    final token = await user.getIdTokenResult(true);
    if (token.claims?['admin'] != true) {
      throw StateError(
        'Admin authorization is not active on this session. Sign out and sign in again after setting the admin claim.',
      );
    }
  }
}
