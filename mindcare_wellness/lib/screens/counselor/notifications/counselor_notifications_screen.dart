import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../counselor_theme.dart';

class CounselorNotificationsScreen extends StatefulWidget {
  const CounselorNotificationsScreen({super.key});

  @override
  State<CounselorNotificationsScreen> createState() =>
      _CounselorNotificationsScreenState();
}

class _CounselorNotificationsScreenState
    extends State<CounselorNotificationsScreen> {
  late final Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificationService().mine();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data ?? const <NotificationModel>[];
        if (notifications.isEmpty) {
          return const Center(child: Text('You are all caught up.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _NotificationTile(item: notifications[index]),
        );
      },
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final NotificationModel item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.isRead ? null : () => NotificationService().markRead(item.id),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFE7F9EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead ? Colors.black12 : const Color(0xFF9DDEAD),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none_rounded, color: dashboardGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: dashboardInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.body, style: const TextStyle(color: Colors.black54)),
                if (!item.isRead)
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'Tap to mark as read',
                      style: TextStyle(
                        color: dashboardGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
