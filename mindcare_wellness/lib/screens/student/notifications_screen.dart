import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/student_notification_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_message.dart';
import '../../widgets/common/loading.dart';

/// Notification `type` that belongs to the "Reminders" tab.
/// Every other type is shown under "Alerts".
const _reminderType = 'reminder';

/// Student notifications: read, mark as read, mark all read, delete, clear.
class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({this.service, super.key});

  final StudentNotificationService? service;

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  late final StudentNotificationService _service =
      widget.service ?? StudentNotificationService();
  late final Stream<List<NotificationModel>> _stream = _service.mine();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failure,
    String? success,
  }) async {
    try {
      await action();
      if (success != null) _snack(success);
    } catch (_) {
      _snack(failure);
    }
  }

  Future<void> _open(NotificationModel n) async {
    if (n.isRead) return;
    await _run(
      () => _service.markRead(n.id),
      failure: 'Could not update the notification.',
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('Every notification will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      _service.clearAll,
      success: 'Notifications cleared',
      failure: 'Could not clear notifications. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: StreamBuilder<List<NotificationModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <NotificationModel>[];
          final unread = items.where((n) => !n.isRead).length;
          final reminders = items.where((n) => n.type == _reminderType).toList();
          final alerts = items.where((n) => n.type != _reminderType).toList();

          Widget body;
          if (snapshot.hasError) {
            body = const ErrorMessage(
              message: 'We could not load your notifications. Please try again.',
            );
          } else if (!snapshot.hasData) {
            body = const LoadingWidget();
          } else {
            body = TabBarView(
              children: [
                _NotificationList(
                  items: items,
                  emptyMessage: 'No notifications yet.',
                  onOpen: _open,
                  onDelete: _delete,
                ),
                _NotificationList(
                  items: reminders,
                  emptyMessage: 'No reminders yet.',
                  onOpen: _open,
                  onDelete: _delete,
                ),
                _NotificationList(
                  items: alerts,
                  emptyMessage: 'No alerts right now.',
                  onOpen: _open,
                  onDelete: _delete,
                ),
              ],
            );
          }

          return Scaffold(
            backgroundColor: pageBackground,
            appBar: AppBar(
              title: Text(
                unread > 0 ? 'Notifications ($unread new)' : 'Notifications',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Mark all as read',
                  onPressed: unread == 0
                      ? null
                      : () => _run(
                          _service.markAllRead,
                          success: 'All marked as read',
                          failure: 'Could not update notifications.',
                        ),
                  icon: const Icon(Icons.done_all_rounded),
                ),
                TextButton(
                  onPressed: items.isEmpty ? null : _clearAll,
                  child: const Text('CLEAR'),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Reminders'),
                  Tab(text: 'Alerts'),
                ],
              ),
            ),
            body: body,
          );
        },
      ),
    );
  }

  Future<void> _delete(NotificationModel n) => _run(
    () => _service.delete(n.id),
    success: 'Notification deleted',
    failure: 'Could not delete the notification.',
  );
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.emptyMessage,
    required this.onOpen,
    required this.onDelete,
  });

  final List<NotificationModel> items;
  final String emptyMessage;
  final Future<void> Function(NotificationModel) onOpen;
  final Future<void> Function(NotificationModel) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [EmptyState(message: emptyMessage)],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final n = items[index];
        return Card(
          color: n.isRead ? Colors.white : mintGreen.withValues(alpha: .5),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            isThreeLine: true,
            onTap: () => onOpen(n),
            leading: CircleAvatar(
              backgroundColor: mintGreen,
              foregroundColor: primaryGreen,
              child: Icon(_iconFor(n.type)),
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.body),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(n.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            trailing: IconButton(
              tooltip: 'Delete',
              onPressed: () => onDelete(n),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        );
      },
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case _reminderType:
      return Icons.alarm_rounded;
    case 'appointment':
      return Icons.event_available_rounded;
    case 'message':
      return Icons.chat_bubble_outline_rounded;
    case 'alert':
    case 'emergency':
      return Icons.warning_amber_rounded;
    default:
      return Icons.notifications_none_rounded;
  }
}

/// Shows how recent a notification is (usability issue U-04).
String _timeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
