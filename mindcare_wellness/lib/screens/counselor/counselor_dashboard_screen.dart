import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import 'counselor_theme.dart';
import 'calendar/counselor_calendar_screen.dart';
import 'home/counselor_home_screen.dart';
import 'notes/counselor_notes_screen.dart';
import 'reports/counselor_reports_screen.dart';
import 'notifications/counselor_notifications_screen.dart';

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
  bool _syncing = false;

  Future<void> _syncAppointments() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await service.syncAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointments synced.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sync appointments. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dashboardMint,
    body: IndexedStack(
      index: selectedIndex,
      children: [
        CounselorHomeScreen(
          service: service,
          authService: widget.authService,
          onSync: _syncAppointments,
          syncing: _syncing,
        ),
        CounselorCalendarScreen(
          service: service,
          authService: widget.authService,
          onSync: _syncAppointments,
          syncing: _syncing,
        ),
        CounselorNotesScreen(
          service: service,
          authService: widget.authService,
          onSync: _syncAppointments,
          syncing: _syncing,
        ),
        CounselorReportsScreen(
          service: service,
          authService: widget.authService,
          onSync: _syncAppointments,
          syncing: _syncing,
        ),
        const CounselorNotificationsScreen(),
      ],
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFECFDF5),
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF059669)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF059669),
            ),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(
              Icons.sticky_note_2_rounded,
              color: Color(0xFF059669),
            ),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF059669)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded, color: Color(0xFF059669)),
            label: 'Notifications',
          ),
        ],
      ),
    ),
  );
}
