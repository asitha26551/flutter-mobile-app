import 'package:flutter/material.dart';

import '../../../models/session_note_model.dart';
import 'add_session_note_screen.dart';

class EditSessionNoteScreen extends StatelessWidget {
  const EditSessionNoteScreen({required this.note, super.key});
  final SessionNoteModel note;

  @override
  Widget build(BuildContext context) => SessionNoteEditorScreen(note: note);
}
