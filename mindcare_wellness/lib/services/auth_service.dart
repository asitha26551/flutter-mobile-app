import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required Map<String, dynamic> studentData,
  }) async {
    final credential = await _createAccount(email: email, password: password);
    final user = credential.user!;
    try {
      await _userService.createStudentProfile(
        uid: user.uid,
        fullName: fullName,
        email: user.email ?? email,
        studentData: studentData,
      );
    } catch (_) {
      await user.delete();
      rethrow;
    }
    await user.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> registerCounselor({
    required String fullName,
    required String email,
    required String password,
    required Map<String, dynamic> counselorData,
  }) async {
    final credential = await _createAccount(email: email, password: password);
    final user = credential.user!;
    try {
      await _userService.createCounselorProfile(
        uid: user.uid,
        fullName: fullName,
        email: user.email ?? email,
        counselorData: counselorData,
      );
    } catch (_) {
      await user.delete();
      rethrow;
    }
    await user.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> _createAccount({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    await user.sendEmailVerification();
  }

  Future<User?> reloadUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  Future<bool> isEmailVerified() async {
    final user = await reloadUser();
    if (user?.emailVerified == true) {
      await user!.getIdToken(true);
      await _userService.markEmailVerified(user.uid);
    }
    return user?.emailVerified ?? false;
  }

  Future<bool> hasProfile(String uid) async =>
      (await _userService.getProfile(uid)) != null;

  Future<AppUser?> getProfile(String uid) => _userService.getProfile(uid);
}

String authErrorMessage(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'MindCare account services are not available yet. Please try again shortly.';
  }
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'weak-password':
      return 'Choose a password with at least 8 characters.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'The email or password is incorrect. Please check your details and try again.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    case 'requires-recent-login':
      return 'Please sign in again to complete this action.';
    default:
      return 'We could not complete that request. Please try again.';
  }
}
