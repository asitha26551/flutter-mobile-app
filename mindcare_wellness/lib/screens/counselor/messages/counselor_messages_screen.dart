import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/counselor_service.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';

class CounselorMessagesScreen extends StatelessWidget {
  const CounselorMessagesScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.conversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (snapshot.hasError)
          return const ErrorMessage(
            message: 'Messages are unavailable right now.',
          );
        final docs = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(17),
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Keep in touch with your students.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            if (docs.isEmpty)
              const EmptyState(message: 'No conversations yet.')
            else
              ...docs.map(
                (doc) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: mintGreen,
                      child: Icon(Icons.person, color: primaryGreen),
                    ),
                    title: Text(
                      doc.data()['studentName'] as String? ?? 'Student',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      doc.data()['lastMessage'] as String? ?? 'No messages yet',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
