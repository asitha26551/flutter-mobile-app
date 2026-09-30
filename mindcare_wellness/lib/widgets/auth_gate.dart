import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../screens/auth/account_status_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_counselor_screen.dart';
import '../screens/counselor/counselor_dashboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../services/auth_service.dart';
import 'auth_widgets.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({this.authService, super.key});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();
    return StreamBuilder<User?>(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final user = snapshot.data;
        if (user == null) return LoginScreen(authService: service);
        if (!user.emailVerified) {
          return EmailVerificationScreen(authService: service);
        }
        return FutureBuilder<AppUser?>(
          future: service.getProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return _MissingProfileScreen(authService: service);
            }
            if (profile.role == 'admin') {
              return AdminDashboardScreen(authService: service);
            }
            if ((profile.role == 'student' || profile.role == 'client') &&
                profile.accountStatus == 'active') {
              return StudentHomeScreen(authService: service);
            }
            if ((profile.role == 'student' || profile.role == 'client') &&
                profile.accountStatus == 'suspended') {
              return AccountStatusScreen(
                status: profile.accountStatus,
                role: 'student',
                authService: service,
              );
            }
            if (profile.role == 'counselor') {
              if (profile.accountStatus == 'pending') {
                return PendingCounselorScreen(authService: service);
              }
              if (profile.verificationStatus == 'approved' &&
                  profile.accountStatus == 'active') {
                return CounselorDashboardScreen(authService: service);
              }
              return AccountStatusScreen(
                status: profile.accountStatus,
                authService: service,
              );
            }
            return _RoleUnavailableScreen(
              role: profile.role,
              authService: service,
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _MissingProfileScreen extends StatelessWidget {
  const _MissingProfileScreen({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => _GateMessage(
    title: 'Profile unavailable',
    message: 'We could not find your MindCare profile. Please sign in again or contact support.',
    authService: authService,
  );
}

class _RoleUnavailableScreen extends StatelessWidget {
  const _RoleUnavailableScreen({required this.role, required this.authService});

  final String role;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => _GateMessage(
    title: 'Area not available',
    message:
        'Your $role account is not enabled in this version of MindCare Wellness.',
    authService: authService,
  );
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({
    required this.title,
    required this.message,
    required this.authService,
  });

  final String title;
  final String message;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: primaryGreen, size: 56),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: authService.logout,
              child: const Text('RETURN TO LOGIN'),
            ),
          ],
        ),
      ),
    ),
  );
}
