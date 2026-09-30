import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../widgets/auth_widgets.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({
    required this.user,
    required this.adminService,
    super.key,
  });

  final AdminUserRecord user;
  final AdminService adminService;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  bool _busy = false;

  Future<void> _changeStatus() async {
    final suspended = widget.user.accountStatus == 'suspended';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(suspended ? 'Reactivate student?' : 'Suspend student?'),
        content: Text(
          suspended ? 'This will restore access to the student account.' : 'This will prevent the student from accessing protected features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(suspended ? 'Reactivate' : 'Suspend'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      if (suspended) {
        await widget.adminService.reactivateUser(widget.user);
      } else {
        await widget.adminService.suspendUser(widget.user);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update account: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.user.roleData;
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Student details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Header(user: widget.user),
          const SizedBox(height: 20),
          _Section(
            title: 'Profile information',
            values: {
              'Student ID': data['studentId'],
              'University email': widget.user.email,
              'Faculty': data['faculty'],
              'Department': data['department'],
              'Degree / programme': data['degreeProgram'],
              'Academic year': data['academicYear'],
              'Phone': data['phoneNumber'] ?? widget.user.data['phoneNumber'],
              'WhatsApp':
                  data['whatsappNumber'] ?? widget.user.data['whatsappNumber'],
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _changeStatus,
              icon: Icon(
                widget.user.accountStatus == 'suspended'
                    ? Icons.lock_open_outlined
                    : Icons.lock_outline,
              ),
              label: Text(
                widget.user.accountStatus == 'suspended'
                    ? 'REACTIVATE ACCOUNT'
                    : 'SUSPEND ACCOUNT',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AdminUserRecord user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: mintGreen,
              foregroundColor: primaryGreen,
              child: Icon(Icons.school_outlined, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _title(user.status),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: values.entries
                  .map((entry) => _Row(label: entry.key, value: entry.value))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              displayValue?.isNotEmpty == true ? displayValue! : '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _title(String value) =>
    value.isEmpty ? 'Active' : value[0].toUpperCase() + value.substring(1);
