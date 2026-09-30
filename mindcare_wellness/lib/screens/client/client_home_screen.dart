import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('MindCare Wellness', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: 'Log out', onPressed: () => authService.logout(), icon: const Icon(Icons.logout_rounded))],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Your wellbeing matters.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Find a moment of support when you need it.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: mintGreen, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.favorite_outline_rounded, color: primaryGreen, size: 30), SizedBox(width: 14), Expanded(child: Text('Take a gentle pause today. Small steps count.', style: TextStyle(fontWeight: FontWeight.w600, height: 1.35)))])),
        const SizedBox(height: 28),
        const Text('How can we help?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 14),
        _ActionTile(icon: Icons.search_rounded, title: 'Find a counselor', subtitle: 'Connect with the right professional'),
        _ActionTile(icon: Icons.calendar_month_rounded, title: 'Book a session', subtitle: 'Choose a time that works for you'),
        _ActionTile(icon: Icons.person_outline_rounded, title: 'My profile', subtitle: 'Manage your personal details'),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle});

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
