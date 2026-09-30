import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({required this.status, required this.authService, super.key});

  final String status;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final suspended = status == 'suspended';
    final title = suspended ? 'Account suspended' : 'Application not approved';
    final message = suspended ? 'This counselor account is currently suspended. Please contact the university counseling administrator.' : 'This counselor application was not approved. Please contact the university counseling administrator for more information.';
    return AuthShell(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Icon(suspended ? Icons.lock_outline_rounded : Icons.info_outline_rounded, color: primaryGreen, size: 58),
      const SizedBox(height: 22),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.45)),
      const SizedBox(height: 26),
      OutlinedButton.icon(onPressed: authService.logout, icon: const Icon(Icons.logout_rounded), label: const Text('RETURN TO LOGIN')),
    ]));
  }
}
