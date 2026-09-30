import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../widgets/auth_widgets.dart';

class CounselorReviewScreen extends StatefulWidget {
  const CounselorReviewScreen({
    required this.user,
    required this.adminService,
    super.key,
  });

  final AdminUserRecord user;
  final AdminService adminService;

  @override
  State<CounselorReviewScreen> createState() => _CounselorReviewScreenState();
}

class _CounselorReviewScreenState extends State<CounselorReviewScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await _confirm(
      'Approve counselor?',
      'This grants access to counselor functionality.',
    );
    if (confirmed) {
      await _run(() => widget.adminService.approveCounselor(widget.user.uid));
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject counselor application?'),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Explain what needs attention',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.isEmpty) return;
    await _run(
      () => widget.adminService.rejectCounselor(widget.user.uid, reason),
    );
  }

  Future<void> _suspendOrReactivate() async {
    final suspended = widget.user.accountStatus == 'suspended';
    final confirmed = await _confirm(
      suspended ? 'Reactivate counselor?' : 'Suspend counselor?',
      suspended
          ? 'This restores counselor access.'
          : 'This prevents counseling services and availability access.',
    );
    if (!confirmed) return;
    await _run(
      () => suspended
          ? widget.adminService.reactivateUser(widget.user)
          : widget.adminService.suspendUser(widget.user),
    );
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update application: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.user.roleData;
    final status = widget.user.status;
    final isPending = status == 'pending';
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Counselor verification',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: mintGreen,
                    foregroundColor: primaryGreen,
                    child: Icon(Icons.support_agent_outlined, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${_label(status)}',
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
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'Personal information',
            values: {
              'Email': widget.user.email,
              'Phone': data['phoneNumber'] ?? widget.user.data['phoneNumber'],
              'WhatsApp':
                  data['whatsappNumber'] ?? widget.user.data['whatsappNumber'],
            },
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Professional information',
            values: {
              'Counselor / staff ID': data['staffId'],
              'Department': data['department'],
              'Qualification': data['qualification'],
              'Qualification institution': data['qualificationInstitution'],
              'Specializations': data['specializations'],
              'Years of experience': data['yearsOfExperience'],
              'Registration number': data['registrationNumber'],
              'Registration body': data['registrationBody'],
              'Biography': data['professionalBio'],
              'Languages': data['languages'],
              'Session types': data['sessionTypes'],
              'Office / location': data['officeLocation'],
            },
          ),
          if ((widget.user.data['rejectionReason'] as String?)?.isNotEmpty ==
              true) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Previous decision',
              values: {'Rejection reason': widget.user.data['rejectionReason']},
            ),
          ],
          const SizedBox(height: 22),
          if (isPending) ...[
            FilledButton.icon(
              onPressed: _busy ? null : _approve,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('APPROVE COUNSELOR'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _reject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('REJECT APPLICATION'),
            ),
          ] else if (status == 'approved' || status == 'suspended')
            OutlinedButton.icon(
              onPressed: _busy ? null : _suspendOrReactivate,
              icon: Icon(
                status == 'suspended'
                    ? Icons.lock_open_outlined
                    : Icons.lock_outline,
              ),
              label: Text(
                status == 'suspended'
                    ? 'REACTIVATE COUNSELOR'
                    : 'SUSPEND COUNSELOR',
              ),
            ),
        ],
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
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: values.entries.map((entry) {
                final displayValue = entry.value?.toString().trim();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          displayValue?.isNotEmpty == true
                              ? displayValue!
                              : '-',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

String _label(String value) =>
    value.isEmpty ? 'Active' : value[0].toUpperCase() + value.substring(1);
