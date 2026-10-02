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
      backgroundColor: dashboardMint,
      appBar: AppBar(
        backgroundColor: dashboardMint,
        foregroundColor: dashboardInk,
        elevation: 0,
        title: const Text(
          'Student Clinical Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
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
          const _EncryptedFileBanner(),
          const SizedBox(height: 12),
          _StudentSummaryCard(
            studentLabel: entry.studentLabel,
            appointment: appointment,
            sessionCount: previousEntries.length + 1,
          ),
          const SizedBox(height: 14),
          const Text(
            'Latest clinical session',
            style: TextStyle(color: dashboardInk, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ClinicalSessionCard(entry: entry),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Consultation history',
                  style: TextStyle(color: dashboardInk, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text('${previousEntries.length + 1} Records', style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          _ClinicalSessionCard(entry: entry),
          ...previousEntries.map(
            (previous) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ClinicalSessionCard(entry: previous),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncryptedFileBanner extends StatelessWidget {
  const _EncryptedFileBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFD5F4DC), borderRadius: BorderRadius.circular(12)),
    child: const Row(
      children: [
        Icon(Icons.lock, color: dashboardGreen, size: 18),
        SizedBox(width: 8),
        Expanded(child: Text('ENCRYPTED\nFILE', style: TextStyle(color: dashboardInk, fontSize: 10, fontWeight: FontWeight.w800, height: 1.1))),
        Text('Dr. Perera\nAccess', textAlign: TextAlign.center, style: TextStyle(color: dashboardInk, fontSize: 9, height: 1.1)),
      ],
    ),
  );
}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({required this.studentLabel, required this.appointment, required this.sessionCount});
  final String studentLabel;
  final AppointmentModel? appointment;
  final int sessionCount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFDDF8E6), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_outline, color: dashboardGreen)),
          const SizedBox(width: 10),
          Expanded(child: Text(studentLabel, style: const TextStyle(color: dashboardInk, fontSize: 16, fontWeight: FontWeight.w800))),
          const Text('Alias Mode', style: TextStyle(color: Colors.black54, fontSize: 10)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SummaryMetric(value: '$sessionCount', label: 'Total Sessions')),
          const SizedBox(width: 8),
          Expanded(child: _SummaryMetric(value: _date(appointment?.startAt), label: 'Last Visit')),
          const SizedBox(width: 8),
          const Expanded(child: _SummaryMetric(value: 'Academic', label: 'Stress Concern')),
        ]),
      ]),
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFF0FBF3), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: dashboardGreen, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 8))]),
  );
}

class _ClinicalSessionCard extends StatelessWidget {
  const _ClinicalSessionCard({required this.entry});
  final SessionNoteEntry entry;
  @override
  Widget build(BuildContext context) {
    final appointment = entry.appointment;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.description_outlined, color: dashboardGreen, size: 18),
          const SizedBox(width: 7),
          Expanded(child: Text(_sessionTitle(entry), style: const TextStyle(color: dashboardInk, fontWeight: FontWeight.w800))),
          Text(_date(appointment?.startAt ?? entry.note.createdAt), style: const TextStyle(color: Colors.black54, fontSize: 10)),
        ]),
        const SizedBox(height: 6),
        Text('${_sessionType(appointment?.sessionType)}  •  ${_timeRange(appointment)}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF0FBF3), borderRadius: BorderRadius.circular(10)),
          child: Text(entry.note.note.isEmpty ? 'No note content.' : entry.note.note, style: const TextStyle(color: dashboardInk, fontSize: 11, height: 1.4)),
        ),
      ]),
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
