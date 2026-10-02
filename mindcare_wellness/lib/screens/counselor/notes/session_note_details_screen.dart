import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../services/session_note_service.dart';
import '../counselor_theme.dart';
import 'edit_session_note_screen.dart';

class SessionNoteDetailsScreen extends StatelessWidget {
  const SessionNoteDetailsScreen({
    required this.entry,
    this.appointmentOverride,
    this.previousEntries = const [],
    super.key,
  });

  final SessionNoteEntry entry;
  final AppointmentModel? appointmentOverride;
  final List<SessionNoteEntry> previousEntries;

  @override
  Widget build(BuildContext context) {
    final appointment = appointmentOverride ?? entry.appointment;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Note'),
        actions: [
          IconButton(
            tooltip: 'Edit note',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSessionNoteScreen(note: entry.note),
                ),
              );
              if (updated == true && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          _Section(
            title: 'Student information',
            child: _InfoLine(label: 'Student', value: entry.studentLabel),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Session information',
            child: Column(
              children: [
                _InfoLine(
                  label: 'Date',
                  value: _date(appointment?.startAt ?? entry.note.createdAt),
                ),
                _InfoLine(label: 'Time', value: _timeRange(appointment)),
                _InfoLine(
                  label: 'Session type',
                  value: _sessionType(appointment?.sessionType),
                ),
                const _InfoLine(
                  label: 'Appointment status',
                  value: 'Completed',
                ),
              ],
            ),
          ),
          if (appointment?.reason?.isNotEmpty == true ||
              appointment?.studentNotes?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Student-provided information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appointment?.reason?.isNotEmpty == true)
                    _LabeledText(
                      label: 'Reason for appointment',
                      text: appointment!.reason!,
                    ),
                  if (appointment?.studentNotes?.isNotEmpty == true)
                    _LabeledText(
                      label: 'Student notes',
                      text: appointment!.studentNotes!,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _Section(
            title: 'Counselor session note',
            trailing: const _PrivateBadge(),
            child: Text(
              entry.note.note.isEmpty ? 'No note content.' : entry.note.note,
              style: const TextStyle(
                color: dashboardInk,
                height: 1.5,
                fontSize: 16,
              ),
            ),
          ),
          if (previousEntries.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Previous sessions',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...previousEntries.map(
              (previous) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: dashboardMint,
                  child: Icon(Icons.history, color: dashboardGreen, size: 18),
                ),
                title: Text(
                  _sessionTitle(previous),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_date(previous.appointment?.startAt ?? previous.note.createdAt)}  •  ${_sessionType(previous.appointment?.sessionType)}\n${_preview(previous.note.note)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionNoteDetailsScreen(
                      entry: previous,
                      previousEntries: previousEntries
                          .where((item) => item.note.id != previous.note.id)
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing = const SizedBox.shrink(),
  });
  final String title;
  final Widget child;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: dashboardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: dashboardInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: dashboardInk, height: 1.35)),
      ],
    ),
  );
}

class _PrivateBadge extends StatelessWidget {
  const _PrivateBadge();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.lock_outline, size: 14, color: dashboardGreen),
      SizedBox(width: 4),
      Text(
        'Private',
        style: TextStyle(
          color: dashboardGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

String _date(DateTime? value) => value == null
    ? 'Date not available'
    : '${value.day} ${_months[value.month - 1]} ${value.year}';
String _timeRange(AppointmentModel? appointment) {
  if (appointment == null) return 'Not available';
  final start = appointment.startAt;
  final end = appointment.endAt;
  if (start == null) return 'Time not available';
  String format(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return end == null ? format(start) : '${format(start)} - ${format(end)}';
}

String _sessionType(String? value) => switch (value) {
  'video' => 'Video',
  'audio' => 'Audio',
  'in_person' => 'In-person',
  'chat' => 'Chat',
  _ => 'Counseling session',
};
String _preview(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
String _sessionTitle(SessionNoteEntry entry) {
  final reason = entry.appointment?.reason?.trim();
  return reason == null || reason.isEmpty ? 'Counseling session' : reason;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
