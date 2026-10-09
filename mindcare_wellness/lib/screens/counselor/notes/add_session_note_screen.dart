import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../models/session_note_model.dart';
import '../../../services/session_note_service.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';

class AddSessionNoteScreen extends StatelessWidget {
  const AddSessionNoteScreen({required this.appointment, super.key});
  final CounselorAppointment appointment;

  @override
  Widget build(BuildContext context) => SessionNoteEditorScreen(appointment: appointment);
}

class SessionNoteEditorScreen extends StatefulWidget {
  const SessionNoteEditorScreen({this.appointment, this.note, super.key});

  final CounselorAppointment? appointment;
  final SessionNoteModel? note;

  @override
  State<SessionNoteEditorScreen> createState() => _SessionNoteEditorScreenState();
}

class _SessionNoteEditorScreenState extends State<SessionNoteEditorScreen> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  final _service = SessionNoteService();
  bool _saving = false;

  bool get editing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.note ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final note = _controller.text.trim();
      if (editing) {
        await _service.update(widget.note!.id, note: note);
      } else {
        await _service.create(
          appointmentId: widget.appointment!.id,
          studentId: widget.appointment!.studentId,
          note: note,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editing ? 'Session note updated successfully.' : 'Session note saved successfully.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save session note. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(editing ? 'Edit Session Note' : 'Add Session Note')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          if (widget.appointment != null) ...[
            _SessionInfo(appointment: widget.appointment!),
            const SizedBox(height: 18),
          ],
          const Text('Session Note', style: TextStyle(color: dashboardInk, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('This note is private to authorized counselors.', style: TextStyle(color: dashboardGreen, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _controller,
            minLines: 9,
            maxLines: 16,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Enter your private session notes...', alignLabelWithHint: true),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a session note.' : null,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save Note'),
          ),
        ],
      ),
    ),
  );
}

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.appointment});
  final CounselorAppointment appointment;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          _Info(label: 'Student', value: appointment.studentAlias),
          _Info(label: 'Date', value: _date(appointment.startAt)),
          _Info(label: 'Time', value: appointmentRange(appointment)),
          _Info(label: 'Session type', value: appointment.sessionType),
        ],
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: dashboardInk, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}

String _date(DateTime? value) => value == null ? 'Date not available' : '${value.day}/${value.month}/${value.year}';
