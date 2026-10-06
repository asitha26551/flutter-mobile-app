import 'package:flutter/material.dart';

import '../../services/counselor_service.dart';
import 'counselor_theme.dart';

class CounselorProfileScreen extends StatefulWidget {
  const CounselorProfileScreen({required this.service, super.key});

  final CounselorService service;

  @override
  State<CounselorProfileScreen> createState() => _CounselorProfileScreenState();
}

class _CounselorProfileScreenState extends State<CounselorProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _roleController = TextEditingController();
  final _bioController = TextEditingController();
  final _officeController = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.service.getProfile();
      if (!mounted) return;
      _fullNameController.text = profile.user['fullName'] as String? ?? '';
      _phoneController.text = profile.user['phoneNumber'] as String? ?? '';
      _departmentController.text = profile.details['department'] as String? ?? '';
      _roleController.text = profile.details['professionalRole'] as String? ?? '';
      _bioController.text = profile.details['professionalBio'] as String? ?? '';
      _officeController.text = profile.details['officeLocation'] as String? ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.updateProfile(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        department: _departmentController.text,
        professionalRole: _roleController.text,
        professionalBio: _bioController.text,
        officeLocation: _officeController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
        title: const Text('My profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(labelText: 'Department'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(labelText: 'Professional role'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _officeController,
            decoration: const InputDecoration(labelText: 'Office location'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Professional bio'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save changes'),
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
