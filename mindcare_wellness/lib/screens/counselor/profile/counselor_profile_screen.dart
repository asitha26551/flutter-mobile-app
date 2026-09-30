import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../counselor_theme.dart';

class CounselorProfileScreen extends StatelessWidget {
  const CounselorProfileScreen({
    required this.service,
    required this.authService,
    super.key,
  });
  final CounselorService service;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(
    future: service.getProfile(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const LoadingWidget();
      if (snapshot.hasError || snapshot.data == null)
        return const ErrorMessage(message: 'Profile is unavailable right now.');
      final profile = snapshot.data!;
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(17),
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mintGreen,
                  backgroundImage: profile.imageUrl == null
                      ? null
                      : NetworkImage(profile.imageUrl!),
                  child: profile.imageUrl == null
                      ? const Icon(Icons.person, color: dashboardGreen)
                      : null,
                ),
                title: Text(
                  profile.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${profile.professionalRole}\n${profile.department}',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(profile.user['email'] as String? ?? 'Email'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(
                      profile.user['phoneNumber'] as String? ??
                          'Phone not added',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: authService.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      );
    },
  );
}
