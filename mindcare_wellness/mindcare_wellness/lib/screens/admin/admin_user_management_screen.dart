import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'admin_user_details_screen.dart';
import 'counselor_review_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({
    required this.authService,
    this.initialRole = 'student',
    this.initialStatus = 'all',
    super.key,
  });

  final AuthService authService;
  final String initialRole;
  final String initialStatus;

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late String _role;
  late String _status;
  final _search = TextEditingController();
  final _adminService = AdminService();
  late Future<List<AdminUserRecord>> _users;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    _status = widget.initialStatus;
    _users = _loadUsers();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<AdminUserRecord>> _loadUsers() =>
      _adminService.getUsers(role: _role);

  void _changeRole(String role) => setState(() {
    _role = role;
    _status = 'all';
    _users = _loadUsers();
  });

  void _refresh() => setState(() => _users = _loadUsers());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'User management',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'student',
                      label: Text('Students'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: 'counselor',
                      label: Text('Counselors'),
                      icon: Icon(Icons.support_agent_outlined),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (value) => _changeRole(value.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search name, email or ID',
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.filter_list_outlined),
                  ),
                  items: _statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_label(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AdminUserRecord>>(
              future: _users,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return _ErrorState(onRetry: _refresh);
                final records = snapshot.data!.where(_matches).toList();
                if (records.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: records.length,
                    itemBuilder: (context, index) => _userTile(records[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _statuses = [
    'all',
    'active',
    'pending',
    'approved',
    'rejected',
    'suspended',
  ];

  bool _matches(AdminUserRecord user) {
    final query = _search.text.trim().toLowerCase();
    final searchable = '${user.fullName} ${user.email} ${user.displayId}'
        .toLowerCase();
    return (_status == 'all' || user.status == _status) &&
        (query.isEmpty || searchable.contains(query));
  }

  Widget _userTile(AdminUserRecord user) {
    final pending = user.role == 'counselor' && user.status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: mintGreen,
          foregroundColor: primaryGreen,
          child: Icon(
            user.role == 'student'
                ? Icons.school_outlined
                : Icons.support_agent_outlined,
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${user.displayId}  •  ${user.email}\n${_label(user.status)}',
        ),
        isThreeLine: true,
        trailing: Icon(
          pending ? Icons.fact_check_outlined : Icons.chevron_right_rounded,
          color: pending ? Colors.orange.shade800 : null,
        ),
        onTap: () async {
          if (user.role == 'counselor') {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CounselorReviewScreen(
                  user: user,
                  adminService: _adminService,
                ),
              ),
            );
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminUserDetailsScreen(
                  user: user,
                  adminService: _adminService,
                ),
              ),
            );
          }
          if (mounted) _refresh();
        },
      ),
    );
  }

  String _label(String value) => value[0].toUpperCase() + value.substring(1);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 42),
        const SizedBox(height: 12),
        const Text('Unable to load users.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
