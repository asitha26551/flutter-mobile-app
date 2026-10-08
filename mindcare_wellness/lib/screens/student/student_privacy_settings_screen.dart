import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../counselor/counselor_theme.dart';

class StudentPrivacySettingsScreen extends StatefulWidget {
  const StudentPrivacySettingsScreen({required this.studentId, super.key});

  final String studentId;

  @override
  State<StudentPrivacySettingsScreen> createState() => _StudentPrivacySettingsScreenState();
}

class _StudentPrivacySettingsScreenState extends State<StudentPrivacySettingsScreen> {
  final _studentService = StudentService();
  final _aliasController = TextEditingController();
  bool _isLoading = true;
  bool _saving = false;
  StudentModel? _student;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    final student = await _studentService.get(widget.studentId);
    if (!mounted) return;
    setState(() {
      _student = student ?? StudentModel(uid: widget.studentId);
      _aliasController.text = _student?.alias ?? '';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final alias = _aliasController.text.trim();
    final isAnonymous = _student?.isAnonymous ?? false;
    if (isAnonymous && alias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an alias before enabling Anonymous Mode.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _studentService.updateAnonymousMode(
        studentId: widget.studentId,
        isAnonymous: isAnonymous,
      );
      if (alias.isNotEmpty) {
        await _studentService.updateStudent(
          studentId: widget.studentId,
          data: {'alias': alias, 'updatedAt': FieldValue.serverTimestamp()},
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy setting saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save privacy setting.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: dashboardMint,
        body: Center(child: CircularProgressIndicator(color: dashboardGreen)),
      );
    }

    return Scaffold(
      backgroundColor: dashboardMint,
      appBar: AppBar(
        backgroundColor: dashboardMint,
        foregroundColor: dashboardInk,
        elevation: 0,
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Anonymous Mode',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'When enabled, counselors see your alias instead of your real name.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: _student?.isAnonymous ?? false,
            onChanged: (value) {
              setState(() {
                _student = _student?.copyWith(isAnonymous: value) ??
                    StudentModel(uid: widget.studentId, isAnonymous: value);
              });
              if (value && _aliasController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add a custom alias before turning Anonymous Mode on.')),
                );
              }
            },
            title: const Text('Anonymous Mode'),
            subtitle: const Text('Use alias only for counselor-facing identity'),
            activeThumbColor: dashboardGreen,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _aliasController,
            decoration: const InputDecoration(
              labelText: 'Alias',
              hintText: 'e.g. Sky',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save settings'),
            style: FilledButton.styleFrom(
              backgroundColor: dashboardGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
