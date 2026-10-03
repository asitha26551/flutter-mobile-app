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
    backgroundColor: dashboardMint,
    appBar: AppBar(
      backgroundColor: dashboardMint,
      foregroundColor: dashboardInk,
      elevation: 0,
      title: const Text(
        'Appointment details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _WorkspaceHeader(status: item.status),
        const SizedBox(height: 12),
        _StudentIdentityCard(item: item),
        const SizedBox(height: 12),
        _AppointmentInfoCard(item: item),
        const SizedBox(height: 12),
        _ClinicalSummaryCard(item: item),
        if (item.meetingLink?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _Detail(label: 'Meeting link', value: item.meetingLink!),
        ],
        const SizedBox(height: 6),
        _AppointmentNotes(item: item),
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

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      ),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COUNSELOR PORTAL',
              style: TextStyle(
                color: dashboardGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            Text(
              'Active Session Workspace',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      _DetailsChip(
        label: status == 'confirmed' ? 'ACTIVE' : appointmentStatusLabel(status),
        color: status == 'rejected' ? const Color(0xFFC62828) : dashboardGreen,
      ),
    ],
  );
}

class _StudentIdentityCard extends StatelessWidget {
  const _StudentIdentityCard({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) => _DetailsPanel(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFDDF8E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: dashboardGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.studentAlias,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Student account',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.more_vert, color: Colors.black38),
      ],
    ),
  );
}

class _AppointmentInfoCard extends StatelessWidget {
  const _AppointmentInfoCard({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) => _DetailsPanel(
    child: Row(
      children: [
        Expanded(
          child: _InfoCell(
            icon: Icons.calendar_today_outlined,
            label: 'DATE & TIME',
            value: _detailDate(item.startAt),
            secondary: appointmentRange(item),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoCell(
            icon: Icons.location_on_outlined,
            label: 'LOCATION & TYPE',
            value: item.location?.isNotEmpty == true
                ? item.location!
                : 'Location not set',
            secondary: _detailSessionType(item.sessionType),
          ),
        ),
      ],
    ),
  );
}

class _ClinicalSummaryCard extends StatelessWidget {
  const _ClinicalSummaryCard({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) => _DetailsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_outlined, color: dashboardGreen, size: 19),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Clinical summary',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _DetailsChip(
              label: item.status == 'rejected' ? 'REVIEW' : 'PRIORITY: NORMAL',
              color: item.status == 'rejected'
                  ? const Color(0xFFC62828)
                  : dashboardGreen,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FBF3),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRIMARY CLINICAL FOCUS',
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.reason,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD6EBDD)),
    ),
    child: child,
  );
}

class _DetailsChip extends StatelessWidget {
  const _DetailsChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.secondary,
  });
  final IconData icon;
  final String label;
  final String value;
  final String secondary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FBF3),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: dashboardGreen, size: 16),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: dashboardGreen,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
      ],
    ),
  );
}

String _detailDate(DateTime? date) => date == null
    ? 'Date not set'
    : '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

String _monthName(int month) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month - 1];

String _detailSessionType(String value) => switch (value) {
  'in_person' => 'In-Person',
  'video' => 'Video consultation',
  'audio' => 'Audio session',
  'chat' => 'Chat session',
  _ => value,
};

class _SessionNoteAction extends StatelessWidget {
  const _SessionNoteAction({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) {
    final appointment = AppointmentModel.fromMap(item.id, item.data);
    return StreamBuilder<List<SessionNoteModel>>(
      stream: SessionNoteService().forAppointment(item.id),
      builder: (context, snapshot) {
        final notes = [...snapshot.data ?? const <SessionNoteModel>[]]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
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

class _AppointmentNotes extends StatefulWidget {
  const _AppointmentNotes({required this.item});
  final CounselorAppointment item;

  @override
  State<_AppointmentNotes> createState() => _AppointmentNotesState();
}

class _AppointmentNotesState extends State<_AppointmentNotes> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SessionNoteModel>>(
    stream: SessionNoteService().forStudent(widget.item.studentId),
    builder: (context, snapshot) {
      final notes = [...snapshot.data ?? const <SessionNoteModel>[]]
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
      if (notes.isEmpty) return const SizedBox.shrink();
      final visibleNotes = expanded ? notes : notes.take(2).toList();
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6EBDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  color: dashboardGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Previous summaries',
                    style: TextStyle(
                      color: dashboardInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                    style: const TextStyle(
                      color: dashboardGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...visibleNotes.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleNotes.length - 1 ? 0 : 8,
                ),
                child: _SummaryPreview(note: entry.value),
              ),
            ),
            if (notes.length > 2)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => expanded = !expanded),
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  label: Text(expanded ? 'Show less' : 'View all summaries'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _SummaryPreview extends StatelessWidget {
  const _SummaryPreview({required this.note});
  final SessionNoteModel note;

  @override
  Widget build(BuildContext context) {
    final text = note.note.trim();
    final date = note.createdAt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF3),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date == null ? 'Session summary' : _summaryDate(date),
            style: const TextStyle(
              color: dashboardInk,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text.isEmpty ? 'No summary recorded.' : text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _summaryDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
