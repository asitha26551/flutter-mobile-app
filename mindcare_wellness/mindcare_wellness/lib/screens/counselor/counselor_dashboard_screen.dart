import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import 'counselor_theme.dart';
import 'calendar/counselor_calendar_screen.dart';
import 'home/counselor_home_screen.dart';
import 'notes/counselor_notes_screen.dart';
import 'reports/counselor_reports_screen.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<CounselorDashboardScreen> createState() =>
      _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  final service = CounselorService();
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dashboardMint,
    body: IndexedStack(
      index: selectedIndex,
      children: [
        CounselorHomeScreen(service: service, authService: widget.authService),
        CounselorCalendarScreen(service: service),
        CounselorNotesScreen(service: service),
        CounselorReportsScreen(service: service),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      height: 70,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.sticky_note_2_outlined),
          selectedIcon: Icon(Icons.sticky_note_2),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
      ],
    ),
  );
}
