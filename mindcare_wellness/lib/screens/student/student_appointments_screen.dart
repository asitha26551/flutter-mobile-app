import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../services/appointment_service.dart';
import '../../widgets/common/session_action_resolver.dart';

class StudentAppointmentsScreen extends StatefulWidget {
  StudentAppointmentsScreen({super.key, AppointmentService? service})
    : service = service ?? AppointmentService();

  final AppointmentService service;

  @override
  State<StudentAppointmentsScreen> createState() =>
      _StudentAppointmentsScreenState();
}

class _StudentAppointmentsScreenState extends State<StudentAppointmentsScreen> {
  late final Stream<List<AppointmentModel>> _appointmentsStream;

  static const _green = Color(0xFF059669);
  static const _ink = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _appointmentsStream = widget.service.forStudent();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: const Text(
        'My appointments',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    body: StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AppointmentsEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Appointments unavailable',
            detail: 'Please try again in a moment.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final appointments = [...snapshot.data!]
          ..sort(
            (a, b) => (a.startAt ?? DateTime(2100)).compareTo(
              b.startAt ?? DateTime(2100),
            ),
          );
        if (appointments.isEmpty) {
          return const _AppointmentsEmptyState(
            icon: Icons.event_available_outlined,
            title: 'No appointments yet',
            detail: 'Your appointment requests and sessions will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _AppointmentCard(
            appointment: appointments[index],
            service: widget.service,
            onSessionAction: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  appointments[index].sessionType == 'audio'
                      ? 'Audio calls are not available in this app yet.'
                      : 'Chat sessions are not available in this app yet.',
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _AppointmentsEmptyState extends StatelessWidget {
  const _AppointmentsEmptyState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF059669), size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppointmentCard extends StatefulWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.service,
    required this.onSessionAction,
  });

  final AppointmentModel appointment;
  final AppointmentService service;
  final VoidCallback onSessionAction;

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _withdrawing = false;

  static const _green = Color(0xFF059669);
  static const _ink = Color(0xFF0F172A);

  Future<void> _withdraw() async {
    final shouldWithdraw = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw appointment request?'),
        content: const Text(
          'The counselor has not confirmed this appointment yet. You can submit a new request later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (shouldWithdraw != true || !mounted) return;

    setState(() => _withdrawing = true);
    try {
      await widget.service.withdrawPending(widget.appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request withdrawn.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not withdraw the request: $error')),
      );
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final status = appointment.status.toLowerCase();
    final pending = status == 'pending';
    final statusColor = switch (status) {
      'confirmed' || 'rescheduled' => _green,
      'pending' => const Color(0xFFB54708),
      'rejected' || 'cancelled' => const Color(0xFFB42318),
      _ => const Color(0xFF475467),
    };
    final sessionColor = switch (appointment.sessionType) {
      'video' => const Color(0xFF2563EB),
      'audio' => const Color(0xFF7C3AED),
      'chat' => const Color(0xFF0891B2),
      _ => _green,
    };
    final actionModel = CounselorAppointment(
      id: appointment.id,
      data: {
        'status': status,
        'sessionType': appointment.sessionType,
        'meetingLink': appointment.meetingLink,
        'location': appointment.location,
      },
    );
    final action = SessionActionResolver.studentAction(
      item: actionModel,
      context: context,
      onOpenChat: widget.onSessionAction,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sessionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_sessionIcon(appointment.sessionType), color: sessionColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _sessionLabel(appointment.sessionType),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(label: _statusLabel(status), color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18, color: _green),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _dateRange(appointment, context),
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (appointment.location?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: appointment.location!,
            ),
          ],
          if (appointment.reason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.notes_rounded, text: appointment.reason!),
          ],
          if (status == 'rejected' &&
              appointment.rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _MessagePanel(
              title: 'Counselor message',
              message: appointment.rejectionReason!,
              color: const Color(0xFFFEF3F2),
            ),
          ],
          if (status == 'cancelled' &&
              appointment.cancellationReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _MessagePanel(
              title: 'Cancellation note',
              message: appointment.cancellationReason!,
              color: const Color(0xFFF2F4F7),
            ),
          ],
          if (action != null || pending) ...[
            const SizedBox(height: 14),
            if (action != null) action,
            if (pending) ...[
              if (action != null) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _withdrawing ? null : _withdraw,
                  icon: _withdrawing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.undo_rounded, size: 18),
                  label: Text(_withdrawing ? 'Withdrawing…' : 'Withdraw request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.35,
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: const Color(0xFF667085)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF475467), fontSize: 13),
        ),
      ),
    ],
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(message, style: const TextStyle(color: Color(0xFF475467))),
      ],
    ),
  );
}

String _dateRange(AppointmentModel item, BuildContext context) {
  final start = item.startAt;
  if (start == null) return 'Time to be confirmed';
  final end = item.endAt;
  final date = MaterialLocalizations.of(context).formatMediumDate(start);
  final startTime = TimeOfDay.fromDateTime(start).format(context);
  final endTime = end == null ? null : TimeOfDay.fromDateTime(end).format(context);
  return '$date · $startTime${endTime == null ? '' : ' – $endTime'}';
}

IconData _sessionIcon(String value) => switch (value) {
  'video' => Icons.videocam_outlined,
  'audio' => Icons.phone_outlined,
  'chat' => Icons.chat_bubble_outline_rounded,
  _ => Icons.person_pin_circle_outlined,
};

String _sessionLabel(String value) => switch (value) {
  'video' => 'Video appointment',
  'audio' => 'Audio appointment',
  'chat' => 'Chat appointment',
  'in_person' => 'In-person appointment',
  _ => 'Appointment',
};

String _statusLabel(String value) => value.replaceAll('_', ' ').toUpperCase();
