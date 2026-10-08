import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import '../auth/login_screen.dart';
import 'counselor_profile_screen.dart';
import 'counselor_theme.dart';

class CounselorPageHeader extends StatelessWidget {
  const CounselorPageHeader({
    required this.title,
    required this.service,
    required this.authService,
    required this.onSync,
    required this.syncing,
    super.key,
  });

  final String title;
  final CounselorService service;
  final AuthService authService;
  final Future<void> Function() onSync;
  final bool syncing;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(authService: authService)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    color: dashboardMint,
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDCEFE1)),
          ),
          child: const Icon(Icons.shield_outlined, color: dashboardGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COUNSELOR PORTAL',
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sync appointments',
          onPressed: syncing ? null : onSync,
          icon: syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: dashboardGreen,
                  ),
                )
              : const Icon(Icons.sync_rounded, color: dashboardGreen),
        ),
        PopupMenuButton<String>(
          tooltip: 'Counselor profile',
          onSelected: (value) async {
            if (value == 'profile') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CounselorProfileScreen(service: service),
                ),
              );
            } else if (value == 'logout') {
              await _logout(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('Counselor Profile')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDDF8E6),
            child: Icon(Icons.person, color: dashboardGreen, size: 22),
          ),
        ),
      ],
    ),
  );
}
