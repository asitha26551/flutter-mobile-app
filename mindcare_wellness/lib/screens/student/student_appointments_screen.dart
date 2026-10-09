import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../services/appointment_service.dart';
import '../../widgets/common/session_action_resolver.dart';

class StudentAppointmentsScreen extends StatelessWidget {
  StudentAppointmentsScreen({super.key, AppointmentService? service})
    : _service = service ?? AppointmentService();

  final AppointmentService _service;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My appointments')),
    body: StreamBuilder<List<AppointmentModel>>(
      stream: _service.forStudent(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load appointments.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = [...snapshot.data!]
          ..sort(
            (a, b) => (a.startAt ?? DateTime(2100)).compareTo(
              b.startAt ?? DateTime(2100),
            ),
          );
        if (appointments.isEmpty) {
          return const Center(child: Text('No appointments yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _AppointmentCard(
            appointment: appointments[index],
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onSessionAction,
  });

  final AppointmentModel appointment;
  final VoidCallback onSessionAction;

  @override
  Widget build(BuildContext context) {
    final actionModel = CounselorAppointment(
      id: appointment.id,
      data: {
        'status': appointment.status,
        'sessionType': appointment.sessionType,
        'meetingLink': appointment.meetingLink,
        'location': appointment.location,
      },
    );
    final action = SessionActionResolver.studentAction(
      item: actionModel,
      context: context,
      onOpenChat: onSessionAction,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _sessionLabel(appointment.sessionType),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(_statusLabel(appointment.status))),
              ],
            ),
            const SizedBox(height: 6),
            Text(_dateRange(appointment)),
            if (appointment.location?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 5),
              Text('Location: ${appointment.location}'),
            ],
            if (appointment.status == 'rejected' &&
                appointment.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Rejection reason: ${appointment.rejectionReason}'),
            ],
            if (appointment.status == 'cancelled' &&
                appointment.cancellationReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Cancellation reason: ${appointment.cancellationReason}'),
            ],
            const SizedBox(height: 12),
            ?action,
            if (appointment.status == 'confirmed' &&
                appointment.sessionType == 'in_person')
              const Text('Please attend at the location above.'),
          ],
        ),
      ),
    );
  }

  String _dateRange(AppointmentModel item) {
    final start = item.startAt;
    if (start == null) return 'Time to be confirmed';
    final end = item.endAt;
    final date =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final startTime = TimeOfDay.fromDateTime(start).formatFromContext;
    final endTime = end == null
        ? null
        : TimeOfDay.fromDateTime(end).formatFromContext;
    return '$date · $startTime${endTime == null ? '' : ' – $endTime'}';
  }
}

extension on TimeOfDay {
  String get formatFromContext =>
      '${hourOfPeriod == 0 ? 12 : hourOfPeriod}:${minute.toString().padLeft(2, '0')} ${period == DayPeriod.am ? 'AM' : 'PM'}';
}

String _sessionLabel(String value) => switch (value) {
  'video' => 'Video appointment',
  'audio' => 'Audio appointment',
  'chat' => 'Chat appointment',
  'in_person' => 'In-person appointment',
  _ => 'Appointment',
};

String _statusLabel(String value) => value.replaceAll('_', ' ').toUpperCase();
