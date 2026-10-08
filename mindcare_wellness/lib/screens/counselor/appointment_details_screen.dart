import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../models/session_note_model.dart';
import '../../models/student_model.dart';
import '../../services/appointment_service.dart';
import '../../services/counselor_service.dart';
import '../../services/session_note_service.dart';
import '../../services/student_service.dart';
import 'counselor_helpers.dart';
import 'counselor_theme.dart';
import 'notes/add_session_note_screen.dart';
import 'notes/session_note_details_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({
    required this.item,
    required this.service,
    super.key,
  });
  final CounselorAppointment item;
  final CounselorService service;

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _appointmentService = AppointmentService();
  final _noteService = SessionNoteService();
  final _studentService = StudentService();
  final _noteController = TextEditingController();
  Timer? _timer;
  DateTime? _sessionStartedAt;
  SessionNoteModel? _existingNote;
  bool _active = false;
  bool _saving = false;
  bool _loadingNote = false;
  StudentModel? _student;
  bool _prioritySaving = false;

  CounselorAppointment get item => widget.item;

  @override
  void initState() {
    super.initState();
    _loadCurrentNote();
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentNote() async {
    setState(() => _loadingNote = true);
    try {
      final notes = await _noteService.forAppointment(item.id).first;
      if (!mounted) return;
      final sorted = [...notes]
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
      if (sorted.isNotEmpty) {
        _existingNote = sorted.first;
        _noteController.text = sorted.first.note;
      }
    } finally {
      if (mounted) setState(() => _loadingNote = false);
    }
  }

  Future<void> _loadStudentProfile() async {
    try {
      final student = await _studentService.get(item.studentId);
      if (mounted) setState(() => _student = student);
    } catch (_) {
      // The alias fallback remains visible if the counselor lacks profile access.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorized = item.counselorId == widget.service.uid;
    return Scaffold(
      backgroundColor: dashboardMint,
      body: SafeArea(
        top: true,
        bottom: false,
        child: !authorized
            ? const _AccessDenied()
            : _active
            ? _buildActiveWorkspace()
            : _buildAppointmentDetails(),
      ),
    );
  }

  Widget _buildAppointmentDetails() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _WorkspaceHeader(status: item.status),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            _WorkspaceStatus(item: item),
            const SizedBox(height: 12),
            _StudentIdentityCard(item: item, student: _student),
            const SizedBox(height: 12),
            _AppointmentInfoCard(item: item),
            const SizedBox(height: 12),
            _ClinicalSummaryCard(
              item: item,
              priorityLevel: _student?.priorityLevel ?? 'normal',
            ),
            const SizedBox(height: 12),
            _AppointmentNotes(item: item),
            if (item.status == 'pending') ...[
              const SizedBox(height: 18),
              _PendingActions(onUpdate: _update),
            ],
            if (item.status == 'completed') ...[
              const SizedBox(height: 18),
              _SessionNoteAction(item: item),
            ],
          ],
        ),
      ),
      if (item.status == 'confirmed' || item.status == 'rescheduled')
        Material(
          color: Colors.white,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: _SessionActions(
                onStart: _startSession,
                onReschedule: _reschedule,
                onCancel: _cancel,
                onNoShow: _canMarkNoShow ? _markNoShow : null,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildActiveWorkspace() => Column(
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: _WorkspaceHeader(status: 'active'),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            _WorkspaceStatus(
              item: item,
              active: true,
              startedAt: _sessionStartedAt,
            ),
            const SizedBox(height: 12),
            _StudentIdentityCard(item: item, student: _student),
            const SizedBox(height: 12),
            _AppointmentInfoCard(item: item),
            const SizedBox(height: 12),
            _ClinicalSummaryCard(
              item: item,
              priorityLevel: _student?.priorityLevel ?? 'normal',
            ),
            const SizedBox(height: 12),
            _PriorityControl(
              highPriority: _student?.isHighPriority ?? false,
              saving: _prioritySaving,
              onChanged: _setPriority,
            ),
            const SizedBox(height: 12),
            _SessionNotesPanel(
              controller: _noteController,
              loading: _loadingNote,
              saving: _saving,
              elapsed: _elapsed,
              duration: _duration,
              onSave: _saveNote,
            ),
          ],
        ),
      ),
      Material(
        color: Colors.white,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPastNotes(context),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Past Notes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _stopSession,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop Session'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD62828),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Duration get _elapsed => _sessionStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStartedAt!);

  Duration get _duration {
    if (item.startAt == null || item.endAt == null) {
      return const Duration(minutes: 45);
    }
    return item.endAt!.difference(item.startAt!);
  }

  bool get _canStart =>
      item.status == 'confirmed' || item.status == 'rescheduled';
  bool get _canMarkNoShow =>
      item.startAt != null &&
      DateTime.now().difference(item.startAt!).inMinutes >= 15;

  Future<void> _startSession() async {
    if (!_canStart) return;
    setState(() {
      _active = true;
      _sessionStartedAt = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _saveNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      if (_existingNote == null) {
        final id = await _noteService.create(
          appointmentId: item.id,
          studentId: item.studentId,
          note: note,
        );
        _existingNote = SessionNoteModel(
          id: id,
          appointmentId: item.id,
          studentId: item.studentId,
          counselorId: item.counselorId,
          note: note,
        );
      } else {
        await _noteService.update(_existingNote!.id, note: note);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Note saved')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setPriority(bool highPriority) async {
    if (_prioritySaving) return;
    setState(() => _prioritySaving = true);
    try {
      await _studentService.updatePriority(
        studentId: item.studentId,
        priorityLevel: highPriority ? 'high' : 'normal',
      );
      if (mounted) {
        setState(() {
          _student = StudentModel(
            uid: _student?.uid ?? item.studentId,
            studentId: _student?.studentId,
            alias: _student?.alias,
            faculty: _student?.faculty,
            department: _student?.department,
            degreeProgram: _student?.degreeProgram,
            academicYear: _student?.academicYear,
            batch: _student?.batch,
            priorityLevel: highPriority ? 'high' : 'normal',
            createdAt: _student?.createdAt,
            updatedAt: _student?.updatedAt,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              highPriority
                  ? 'Student marked high priority.'
                  : 'Priority returned to normal.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update student priority.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _prioritySaving = false);
    }
  }

  Future<void> _stopSession() async {
    final confirmed = await _confirm(
      'End Session?',
      'Save the current note and end this counseling session?',
    );
    if (!confirmed) return;
    await _saveNote();
    await _appointmentService.complete(item.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cancel() async {
    final confirmed = await _confirm(
      'Cancel Appointment?',
      'Are you sure you want to cancel this appointment?',
    );
    if (!confirmed) return;
    await _appointmentService.cancel(item.id, reason: 'Cancelled by counselor');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reschedule() async {
    final base = item.startAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: base.isBefore(DateTime.now()) ? DateTime.now() : base,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final duration = _duration;
    await _appointmentService.reschedule(
      item.id,
      startAt: start,
      endAt: start.add(duration),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _markNoShow() async {
    await _appointmentService.markNoShow(item.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _update(String status) async {
    await _appointmentService.updateCounselorStatus(item.id, status);
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  void _showPastNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionNoteDetailsScreen(
          entry: SessionNoteEntry(
            note:
                _existingNote ??
                SessionNoteModel(
                  id: '',
                  appointmentId: item.id,
                  studentId: item.studentId,
                  counselorId: item.counselorId,
                  note: '',
                ),
            appointment: AppointmentModel.fromMap(item.id, item.data),
          ),
        ),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: dashboardGreen, size: 42),
          const SizedBox(height: 12),
          const Text(
            "You don't have permission to view this appointment.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dashboardInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    ),
  );
}

class _WorkspaceStatus extends StatelessWidget {
  const _WorkspaceStatus({
    required this.item,
    this.active = false,
    this.startedAt,
  });
  final CounselorAppointment item;
  final bool active;
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final label = active
        ? 'LIVE NOW'
        : item.startAt == null
        ? 'TIME NOT SET'
        : DateTime.now().isAfter(item.endAt ?? item.startAt!)
        ? 'SESSION ENDED'
        : 'ACTIVE WORKSPACE';
    final trailing = active ? 'Session started' : _timeUntil(item.startAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD5F8DF) : const Color(0xFFEAF9EF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: active ? dashboardGreen : Colors.orange,
            size: 9,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: dashboardGreen,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: dashboardGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _timeUntil(DateTime? start) {
  if (start == null) return 'Time not set';
  final difference = start.difference(DateTime.now());
  if (difference.isNegative) return 'Started';
  final minutes = difference.inMinutes;
  return minutes < 1 ? 'Starting now' : 'In $minutes mins';
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({required this.onUpdate});
  final Future<void> Function(String status) onUpdate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: () => onUpdate('confirmed'),
          icon: const Icon(Icons.check),
          label: const Text('Accept'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => onUpdate('rejected'),
          icon: const Icon(Icons.close),
          label: const Text('Decline'),
        ),
      ),
    ],
  );
}

class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.onStart,
    required this.onReschedule,
    required this.onCancel,
    required this.onNoShow,
  });
  final VoidCallback onStart;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('START SESSION'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReschedule,
              icon: const Icon(Icons.schedule),
              label: const Text('Reschedule'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Cancel'),
            ),
          ),
        ],
      ),
      if (onNoShow != null) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onNoShow,
          icon: const Icon(Icons.person_off_outlined, size: 16),
          label: const Text('Mark as Student No-Show'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD62828)),
        ),
      ],
    ],
  );
}

class _SessionNotesPanel extends StatelessWidget {
  const _SessionNotesPanel({
    required this.controller,
    required this.loading,
    required this.saving,
    required this.elapsed,
    required this.duration,
    required this.onSave,
  });
  final TextEditingController controller;
  final bool loading;
  final bool saving;
  final Duration elapsed;
  final Duration duration;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final elapsedText =
        '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return _DetailsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_outlined, color: dashboardGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Session Notes',
                  style: TextStyle(
                    color: dashboardInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _DetailsChip(
                label: 'Timer: $elapsedText / ${duration.inMinutes}m',
                color: dashboardGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !loading && !saving,
            minLines: 7,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add session notes...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Private session notes',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 17),
              label: Text(saving ? 'Saving...' : 'Add Note'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 62,
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(width: 8),
        _DetailsChip(
          label: status == 'confirmed'
              ? 'ACTIVE'
              : appointmentStatusLabel(status),
          color: status == 'rejected'
              ? const Color(0xFFC62828)
              : dashboardGreen,
        ),
        const SizedBox(width: 4),
      ],
    ),
  );
}

class _StudentIdentityCard extends StatelessWidget {
  const _StudentIdentityCard({required this.item, this.student});
  final CounselorAppointment item;
  final StudentModel? student;

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
                student?.alias?.trim().isNotEmpty == true
                    ? student!.alias!
                    : item.studentAlias,
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
              if (student?.faculty?.isNotEmpty == true)
                Text(
                  '${student!.faculty}${student!.academicYear?.isNotEmpty == true ? '  •  ${student!.academicYear}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
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
  const _ClinicalSummaryCard({required this.item, required this.priorityLevel});
  final CounselorAppointment item;
  final String priorityLevel;

  @override
  Widget build(BuildContext context) => _DetailsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.assignment_outlined,
              color: dashboardGreen,
              size: 19,
            ),
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
              label: priorityLevel == 'high'
                  ? 'PRIORITY: HIGH'
                  : 'PRIORITY: NORMAL',
              color: priorityLevel == 'high'
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

class _PriorityControl extends StatelessWidget {
  const _PriorityControl({
    required this.highPriority,
    required this.saving,
    required this.onChanged,
  });
  final bool highPriority;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _DetailsPanel(
    child: Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: highPriority,
        onChanged: saving ? null : (value) => onChanged(value ?? false),
        activeColor: dashboardGreen,
        title: const Text(
          'Mark student as high priority',
          style: TextStyle(
            color: dashboardInk,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Only authorized counselors can change this status.',
          style: TextStyle(color: Colors.black54, fontSize: 11),
        ),
        secondary: const Icon(Icons.priority_high, color: dashboardGreen),
      ),
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
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
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
][month - 1];

String _detailSessionType(String value) => switch (value) {
  'in_person' => 'In-Person',
  'video' => 'Video consultation',
  'audio' => 'Audio session',
  'chat' => 'Chat session',
  _ => value,
};

class _SessionNoteAction extends StatefulWidget {
  const _SessionNoteAction({required this.item});
  final CounselorAppointment item;

  @override
  State<_SessionNoteAction> createState() => _SessionNoteActionState();
}

class _SessionNoteActionState extends State<_SessionNoteAction> {
  late final Stream<List<SessionNoteModel>> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream = SessionNoteService().forAppointment(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = AppointmentModel.fromMap(widget.item.id, widget.item.data);
    return StreamBuilder<List<SessionNoteModel>>(
      stream: _notesStream,
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
                builder: (_) => AddSessionNoteScreen(appointment: widget.item),
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
  late final Stream<List<SessionNoteModel>> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream = SessionNoteService().forCounselor().map(
      (notes) => notes
          .where((note) => note.studentId == widget.item.studentId)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SessionNoteModel>>(
    stream: _notesStream,
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
