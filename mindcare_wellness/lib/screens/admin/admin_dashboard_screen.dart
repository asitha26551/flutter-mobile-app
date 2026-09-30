import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'admin_user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardStats> _stats;
  final _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _stats = _adminService.getDashboardStats();
  }

  void _refresh() => setState(() => _stats = _adminService.getDashboardStats());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text(
          'Admin dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.authService.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'MindCare administration',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Review accounts and keep the care network trusted.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FutureBuilder<AdminDashboardStats>(
              future: _stats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) return _ErrorPanel(onRetry: _refresh);
                final stats = snapshot.data!;
                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _StatTile(
                          label: 'Students',
                          value: stats.students,
                          icon: Icons.school_outlined,
                        ),
                        _StatTile(
                          label: 'Counselors',
                          value: stats.counselors,
                          icon: Icons.support_agent_rounded,
                        ),
                        _StatTile(
                          label: 'Pending review',
                          value: stats.pendingCounselors,
                          icon: Icons.hourglass_top_rounded,
                          accent: Colors.orange.shade800,
                        ),
                        _StatTile(
                          label: 'Approved',
                          value: stats.approvedCounselors,
                          icon: Icons.verified_outlined,
                        ),
                        _StatTile(
                          label: 'Rejected',
                          value: stats.rejectedCounselors,
                          icon: Icons.info_outline_rounded,
                          accent: Colors.deepOrange.shade700,
                        ),
                        _StatTile(
                          label: 'Suspended',
                          value: stats.suspendedUsers,
                          icon: Icons.lock_outline_rounded,
                          accent: Colors.red.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ActionButton(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage users',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserManagementScreen(
                              authService: widget.authService,
                            ),
                          ),
                        );
                        if (mounted) _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.fact_check_outlined,
                      label: 'Review counselor applications',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserManagementScreen(
                              authService: widget.authService,
                              initialRole: 'counselor',
                              initialStatus: 'pending',
                            ),
                          ),
                        );
                        if (mounted) _refresh();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = primaryGreen,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: accent),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text('Unable to load dashboard data.'),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
