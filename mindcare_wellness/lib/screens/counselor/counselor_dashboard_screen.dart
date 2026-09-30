import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class CounselorDashboardScreen extends StatelessWidget {
  const CounselorDashboardScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(title: const Text('Counselor dashboard', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(tooltip: 'Log out', onPressed: authService.logout, icon: const Icon(Icons.logout_rounded))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Welcome to MindCare.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Your approved counselor workspace.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: mintGreen, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.verified_user_outlined, color: primaryGreen, size: 30), SizedBox(width: 14), Expanded(child: Text('Your counselor account is approved.', style: TextStyle(fontWeight: FontWeight.w700)))])),
        const SizedBox(height: 28),
        const Text('Counselor tools', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 14),
        _DashboardTile(icon: Icons.calendar_month_rounded, title: 'Availability', subtitle: 'Set your available session times'),
        _DashboardTile(icon: Icons.event_note_rounded, title: 'Appointments', subtitle: 'Review your upcoming sessions'),
        _DashboardTile(icon: Icons.badge_outlined, title: 'Professional profile', subtitle: 'Manage your counselor information'),
      ]),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(backgroundColor: mintGreen, foregroundColor: primaryGreen, child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
