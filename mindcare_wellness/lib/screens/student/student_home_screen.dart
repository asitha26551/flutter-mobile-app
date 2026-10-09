import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../dashboard/student_dashboard_screen.dart';

/// Primary Student Home screen delivering the Student Privacy,
/// Identity Controls, and Anonymous Booking experience.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StudentDashboardScreen(authService: authService);
  }
}
