import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../models/session_note_model.dart';
import '../../services/appointment_service.dart';
import '../../services/counselor_service.dart';
import '../../services/session_note_service.dart';
import 'counselor_helpers.dart';
import 'counselor_theme.dart';
import 'notes/add_session_note_screen.dart';
import 'notes/session_note_details_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  const AppointmentDetailsScreen({
    required this.item,
    required this.service,
    super.key,
  });
  final CounselorAppointment item;
  final CounselorService service;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Appointment details')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dashboardGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointmentStatusLabel(item.status),
                style: const TextStyle(
                  color: dashboardBright,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.reason,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appointmentRange(item),
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Detail(label: 'Student', value: item.studentAlias),
        _Detail(label: 'Session type', value: item.sessionType),
        _Detail(
          label: 'Location',
          value: item.location?.isNotEmpty == true
              ? item.location!
              : 'Not specified',
        ),
        if (item.meetingLink?.isNotEmpty == true)
          _Detail(label: 'Meeting link', value: item.meetingLink!),
        if (item.status == 'pending') ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _update(context, 'confirmed'),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _update(context, 'rejected'),
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
        if (item.status == 'confirmed') ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _update(context, 'completed'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark completed'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _update(context, 'no_show'),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Mark no show'),
          ),
        ],
        if (item.status == 'completed') ...[
          const SizedBox(height: 22),
          _SessionNoteAction(item: item),
        ],
      ],
    ),
  );

  Future<void> _update(BuildContext context, String status) async {
    await AppointmentService().updateCounselorStatus(item.id, status);
    if (context.mounted) Navigator.pop(context);
  }
}

class _SessionNoteAction extends StatelessWidget {
  const _SessionNoteAction({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) {
    final appointment = AppointmentModel.fromMap(item.id, item.data);
    return StreamBuilder<List<SessionNoteModel>>(
      stream: SessionNoteService().forAppointment(item.id),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? const [];
        if (notes.isEmpty) {
          return FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSessionNoteScreen(appointment: item),
              ),
            ),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Add Session Note'),
          );
        }
        final note = notes.first;
        return OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionNoteDetailsScreen(
                entry: SessionNoteEntry(note: note, appointment: appointment),
                appointmentOverride: appointment,
              ),
            ),
          ),
          icon: const Icon(Icons.sticky_note_2_outlined),
          label: const Text('View Session Note'),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
