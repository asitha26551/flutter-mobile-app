import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/counselor_models.dart';
import '../../services/appointment_service.dart';

/// Resolves the appropriate session action button based on appointment
/// sessionType, status, and user role context.
class SessionActionResolver {
  const SessionActionResolver._();

  /// Whether an appointment is in an actionable (joinable/startable) state.
  static bool isActionable(CounselorAppointment item) {
    final status = item.status;
    return status == 'confirmed' || status == 'rescheduled';
  }

  /// Build the primary session action widget for the counselor.
  static Widget? counselorAction({
    required CounselorAppointment item,
    required AppointmentService service,
    required BuildContext context,
    VoidCallback? onStartInPersonSession,
  }) {
    if (!isActionable(item)) return null;

    switch (item.sessionType) {
      case 'video':
        if (item.meetingLink == null || item.meetingLink!.isEmpty) return null;
        return _ActionButton(
          icon: Icons.videocam_outlined,
          label: 'Start Video Call',
          color: const Color(0xFF1565C0),
          onPressed: () => _launchHostLink(context, item.id, service),
        );
      case 'audio':
        return _ActionButton(
          icon: Icons.phone_outlined,
          label: 'Start Audio Call',
          color: const Color(0xFF2E7D32),
          onPressed: onStartInPersonSession,
        );
      case 'chat':
        return _ActionButton(
          icon: Icons.chat_outlined,
          label: 'Open Chat',
          color: const Color(0xFF6A1B9A),
          onPressed: onStartInPersonSession,
        );
      case 'in_person':
        final location = item.location;
        return _ActionButton(
          icon: Icons.place_outlined,
          label: location?.isNotEmpty == true
              ? 'View Location'
              : 'In-Person Session',
          color: const Color(0xFFE65100),
          onPressed: onStartInPersonSession,
        );
      default:
        return null;
    }
  }

  /// Build the primary session action widget for the student.
  static Widget? studentAction({
    required CounselorAppointment item,
    required BuildContext context,
    VoidCallback? onOpenChat,
  }) {
    if (!isActionable(item)) return null;

    switch (item.sessionType) {
      case 'video':
        final link = item.meetingLink;
        if (link == null || link.isEmpty) return null;
        return _ActionButton(
          icon: Icons.videocam_outlined,
          label: 'Join Video Call',
          color: const Color(0xFF1565C0),
          onPressed: () => _openUrl(context, link),
        );
      case 'audio':
        return _ActionButton(
          icon: Icons.phone_outlined,
          label: 'Join Audio Call',
          color: const Color(0xFF2E7D32),
          onPressed: onOpenChat,
        );
      case 'chat':
        return _ActionButton(
          icon: Icons.chat_outlined,
          label: 'Open Chat',
          color: const Color(0xFF6A1B9A),
          onPressed: onOpenChat,
        );
      case 'in_person':
        final location = item.location;
        return _ActionButton(
          icon: Icons.place_outlined,
          label: location?.isNotEmpty == true
              ? 'View Location'
              : 'In-Person Session',
          color: const Color(0xFFE65100),
          onPressed: null,
        );
      default:
        return null;
    }
  }

  static Future<void> _launchHostLink(
    BuildContext context,
    String appointmentId,
    AppointmentService service,
  ) async {
    try {
      final startUrl = await service.getHostLink(appointmentId);
      if (!context.mounted) return;
      await _openUrl(context, startUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start video call: $e')),
        );
      }
    }
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open link: $e')));
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
