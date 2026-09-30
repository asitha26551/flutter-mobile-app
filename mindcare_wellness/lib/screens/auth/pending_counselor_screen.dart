import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class PendingCounselorScreen extends StatelessWidget {
  const PendingCounselorScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const BrandMark(),
        const SizedBox(height: 24),
        Text('Application under review', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Thank you for registering as a counselor. An authorized university administrator will review your professional information before access is granted.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.45)),
        const SizedBox(height: 28),
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: mintGreen, borderRadius: BorderRadius.circular(18)), child: const Column(children: [Icon(Icons.hourglass_top_rounded, size: 48, color: primaryGreen), SizedBox(height: 12), Text('Pending approval', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen)), SizedBox(height: 5), Text('You will be able to use counselor features after approval.', textAlign: TextAlign.center)])),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: authService.logout, icon: const Icon(Icons.logout_rounded), label: const Text('LOG OUT')),
      ]),
    );
  }
}
