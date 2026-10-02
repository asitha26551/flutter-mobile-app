import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../services/session_note_service.dart';
import '../counselor_theme.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COUNSELOR PORTAL',
              style: TextStyle(
                color: dashboardGreen,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            Text(
              'Student Clinical Details',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          // ── Encrypted File Banner ──
          const _EncryptedFileBanner(),
          const SizedBox(height: 12),

          // ── Student Summary Card ──
          _StudentSummaryCard(
            studentLabel: entry.studentLabel,
            appointment: appointment,
            sessionCount: previousEntries.length + 1,
          ),
          const SizedBox(height: 16),

          // ── Latest Clinical Session section ──
          _SectionHeader(
            label: 'LATEST CLINICAL SESSION',
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD5F4DC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dashboardGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: dashboardGreen, size: 7),
                  SizedBox(width: 4),
                  Text(
                    'Low Risk',
                    style: TextStyle(
                      color: dashboardGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _LatestSessionCard(entry: entry, appointment: appointment),
          const SizedBox(height: 18),

          // ── Consultation History section ──
          _SectionHeader(
            label: 'CONSULTATION HISTORY',
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${previousEntries.length + 1} Records Logged',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Latest entry in history
          _HistorySessionCard(entry: entry, isFirst: true),

          // Previous entries
          ...previousEntries.asMap().entries.map(
            (mapEntry) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _HistorySessionCard(
                entry: mapEntry.value,
                isFirst: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Encrypted File Banner
// ──────────────────────────────────────────
class _EncryptedFileBanner extends StatelessWidget {
  const _EncryptedFileBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFD5F4DC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock, color: dashboardGreen, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'ENCRYPTED\nFILE',
            style: TextStyle(
              color: dashboardInk,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: .3,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Dr. Perera',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Access',
              style: TextStyle(color: Colors.black54, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

// ──────────────────────────────────────────
// Student Summary Card
// ──────────────────────────────────────────
class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({
    required this.studentLabel,
    required this.appointment,
    required this.sessionCount,
  });
  final String studentLabel;
  final AppointmentModel? appointment;
  final int sessionCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF8E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                color: dashboardGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentLabel,
                    style: const TextStyle(
                      color: dashboardInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Alias Mode',
                    style: TextStyle(color: Colors.black45, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.black38, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        // Metrics row
        Row(
          children: [
            Expanded(
              child: _MetricBox(
                icon: Icons.group_outlined,
                value: '$sessionCount',
                label: 'Total Sessions',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricBox(
                icon: Icons.event_outlined,
                value: _shortDate(appointment?.startAt),
                label: 'Last Visit',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _MetricBox(
                icon: Icons.school_outlined,
                value: 'Academic',
                label: 'Stress Concern',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FBF3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, color: dashboardGreen, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: dashboardInk,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 8),
        ),
      ],
    ),
  );
}

// ──────────────────────────────────────────
// Section Header with badge
// ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.badge});
  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFD5F4DC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.note_alt_outlined, color: dashboardGreen, size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: dashboardGreen,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ),
        badge,
      ],
    ),
  );
}

// ──────────────────────────────────────────
// Latest Session Card (prominent)
// ──────────────────────────────────────────
class _LatestSessionCard extends StatelessWidget {
  const _LatestSessionCard({required this.entry, required this.appointment});
  final SessionNoteEntry entry;
  final AppointmentModel? appointment;

  @override
  Widget build(BuildContext context) {
    final title = _sessionTitle(entry);
    final date = appointment?.startAt ?? entry.note.createdAt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Text(
            title,
            style: const TextStyle(
              color: dashboardInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          // Date + type
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.black38,
                size: 12,
              ),
              const SizedBox(width: 5),
              Text(
                _fullDate(date),
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(width: 8),
              const Text('·', style: TextStyle(color: Colors.black38)),
              const SizedBox(width: 8),
              Text(
                _sessionType(appointment?.sessionType),
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Observations label
          const Row(
            children: [
              Icon(Icons.edit_outlined, color: dashboardGreen, size: 13),
              SizedBox(width: 5),
              Text(
                "COUNSELOR'S OBSERVATIONS",
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Note content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBF3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              entry.note.note.isEmpty
                  ? 'No observations recorded.'
                  : '"${entry.note.note}"',
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 12,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// History Session Card (compact with full note)
// ──────────────────────────────────────────
class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({required this.entry, required this.isFirst});
  final SessionNoteEntry entry;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final appointment = entry.appointment;
    final date = appointment?.startAt ?? entry.note.createdAt;
    final title = _sessionTitle(entry);
    final noteText = entry.note.note.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isFirst
            ? Border.all(color: const Color(0xFFB8E8C3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + date
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isFirst
                      ? dashboardGreen
                      : const Color(0xFFE0F4E5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFirst ? Icons.check : Icons.history,
                  color: isFirst ? Colors.white : dashboardGreen,
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: dashboardInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    decoration: isFirst ? null : null,
                  ),
                ),
              ),
              Text(
                _shortMonthDate(date),
                style: const TextStyle(color: Colors.black45, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Session type + duration
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              '${_sessionType(appointment?.sessionType)}  •  ${_timeRange(appointment)}',
              style: const TextStyle(color: Colors.black54, fontSize: 10),
            ),
          ),
          const SizedBox(height: 10),
          // Full note content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FCF6),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              noteText.isEmpty ? 'No note content recorded.' : noteText,
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────
String _shortDate(DateTime? value) =>
    value == null ? '—' : '${_monthsShort[value.month - 1]} ${value.day}';

String _shortMonthDate(DateTime? value) =>
    value == null ? '—' : '${_monthsShort[value.month - 1]} ${value.day}';

String _fullDate(DateTime? value) => value == null
    ? 'Date not available'
    : '${_monthsShort[value.month - 1]} ${value.day}, ${value.year}';

String _timeRange(AppointmentModel? appointment) {
  if (appointment == null) return 'Not available';
  final start = appointment.startAt;
  final end = appointment.endAt;
  if (start == null) return 'Time not available';
  String format(DateTime v) =>
      '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
  return end == null ? format(start) : '${format(start)} – ${format(end)}';
}

String _sessionType(String? value) => switch (value) {
  'video' => 'Video consultation',
  'audio' => 'Audio session',
  'in_person' => 'In-person Review',
  'chat' => 'Chat session',
  _ => 'Counseling session',
};

String _sessionTitle(SessionNoteEntry entry) {
  final reason = entry.appointment?.reason?.trim();
  return reason == null || reason.isEmpty ? 'Counseling session' : reason;
}

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
