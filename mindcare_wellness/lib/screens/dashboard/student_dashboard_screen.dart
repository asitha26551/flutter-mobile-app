import 'package:flutter/material.dart';

import '../../models/counselor_models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/privacy_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../booking/book_appointment_screen.dart';
import '../counselors/counselor_directory_screen.dart';
import '../privacy/privacy_controls_screen.dart';
import '../student/notifications_screen.dart';
import '../student/settings_screen.dart';
import '../student/weekly_wellbeing_screen.dart';
import '../student/student_appointments_screen.dart';

/// Screen 1: Student Dashboard Screen
/// Features a "Privacy Mode: Active" status indicator, interactive mood emoji selector,
/// quick action cards, recommended counselors list with "Book Now" shortcuts,
/// and a 4-tab Bottom Navigation Bar (Home, Schedule, Counselors, Mood Log).
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({
    this.authService,
    this.bookingService,
    this.privacyService,
    this.appointmentService,
    super.key,
  });

  final AuthService? authService;
  final BookingService? bookingService;
  final PrivacyService? privacyService;
  final AppointmentService? appointmentService;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  AuthService? _authService;
  late final BookingService _bookingService;
  late final PrivacyService _privacyService;
  late final AppointmentService _appointmentService;
  late final Stream<List<AppointmentModel>> _appointmentsStream;

  int _selectedTabIndex = 0;

  // Selected mood index & state
  int? _selectedMoodIndex = 1; // Default to "Good 😊"
  final List<_MoodItem> _moods = const [
    _MoodItem('🤩', 'Great'),
    _MoodItem('😊', 'Good'),
    _MoodItem('😐', 'Okay'),
    _MoodItem('😔', 'Down'),
    _MoodItem('😰', 'Stressed'),
  ];

  // Counselors state
  List<CounselorModel> _recommendedCounselors = [];
  bool _isLoadingCounselors = true;

  // Active pseudonym
  String _activePseudonym = 'SilentPanda42';

  // Theme Constants
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _bookingService = widget.bookingService ?? BookingService.defaultInstance;
    _privacyService = widget.privacyService ?? PrivacyService.defaultInstance;
    _appointmentService = widget.appointmentService ?? AppointmentService();
    _appointmentsStream = _appointmentService.forStudent();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout() async {
    if (_authService != null) {
      await _authService!.logout();
    } else {
      try {
        await AuthService().logout();
      } catch (_) {}
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingCounselors = true);
    try {
      final counselors = await _bookingService.fetchCounselors();
      final settings = await _privacyService.getPrivacySettings();

      if (mounted) {
        setState(() {
          _recommendedCounselors = counselors.take(3).toList();
          if (settings.currentPseudonym.isNotEmpty) {
            _activePseudonym = settings.currentPseudonym;
          }
          _isLoadingCounselors = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCounselors = false);
      }
    }
  }

  void _onMoodSelected(int index) {
    setState(() {
      _selectedMoodIndex = index;
    });

    final mood = _moods[index];
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mood logged anonymously: ${mood.label}. Taking care of you.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _emeraldGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigateToBooking(CounselorModel counselor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(
          counselor: counselor,
          bookingService: _bookingService,
          privacyService: _privacyService,
          appointmentService: _appointmentService,
        ),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  void _navigateToCounselorDirectory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CounselorDirectoryScreen(
          bookingService: _bookingService,
          privacyService: _privacyService,
        ),
      ),
    );
  }

  void _navigateToPrivacySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrivacyControlsScreen(
          privacyService: _privacyService,
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          authService: _authService ?? AuthService(),
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: _mintTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: _emeraldGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MindCare Wellness',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Top Bar: "Privacy Mode: Active" status indicator
          _buildPrivacyStatusPill(),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded, size: 21),
            color: const Color(0xFF64748B),
            onPressed: _navigateToNotifications,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, size: 21),
            color: const Color(0xFF64748B),
            onPressed: _navigateToSettings,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: const Color(0xFF64748B),
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
  index: _selectedTabIndex,
  children: [
    _buildHomeDashboardView(),
    _buildScheduleView(),
    CounselorDirectoryScreen(
      bookingService: _bookingService,
      privacyService: _privacyService,
    ),
    WeeklyWellbeingScreen(
      onBackHome: () {
        setState(() {
          _selectedTabIndex = 0;
        });
      },
    ),
  ],
),
bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Top Bar "Privacy Mode: Active" status indicator pill
  Widget _buildPrivacyStatusPill() {
    return GestureDetector(
      onTap: _navigateToPrivacySettings,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: _mintTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _mintBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _emeraldGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.shield_rounded,
              size: 13,
              color: _darkEmerald,
            ),
            const SizedBox(width: 4),
            const Text(
              ' : Active',
              style: TextStyle(
                color: _darkEmerald,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboardView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _emeraldGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          // Hero Greeting Card with active pseudonym
          _buildGreetingBanner(),
          const SizedBox(height: 20),
          _buildAppointmentSummary(),
          const SizedBox(height: 20),

          // "How are you feeling today?" mood emoji selector
          _buildMoodSection(),
          const SizedBox(height: 24),

          // Quick Action Cards
          _buildSectionHeader('Quick Actions', 'Instant wellness tools'),
          const SizedBox(height: 12),
          _buildQuickActionCards(),
          const SizedBox(height: 26),

          // Recommended Counselors List with "Book Now" shortcuts
          _buildSectionHeader(
            'Recommended Counselors',
            'Confidential certified therapists',
            actionText: 'View All',
            onActionTap: () => setState(() => _selectedTabIndex = 2),
          ),
          const SizedBox(height: 12),
          _buildRecommendedCounselorsList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary() => StreamBuilder<List<AppointmentModel>>(
    stream: _appointmentsStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _AppointmentSummaryCard(
          title: 'Appointments unavailable',
          detail: 'We could not load your appointment information.',
          icon: Icons.event_busy_outlined,
        );
      }
      if (!snapshot.hasData) {
        return const _AppointmentSummaryCard(
          title: 'Loading appointments',
          detail: 'Checking your latest appointment requests…',
          icon: Icons.event_outlined,
        );
      }

      final upcoming = snapshot.data!
          .where((item) =>
              (item.status == 'pending' ||
                  item.status == 'confirmed' ||
                  item.status == 'rescheduled') &&
              (item.startAt?.isAfter(DateTime.now()) ?? false))
          .toList()
        ..sort((a, b) => a.startAt!.compareTo(b.startAt!));
      if (upcoming.isEmpty) {
        return _AppointmentSummaryCard(
          title: 'No upcoming appointments',
          detail: 'Your appointment requests and sessions will appear here.',
          icon: Icons.event_available_outlined,
          onTap: () => setState(() => _selectedTabIndex = 2),
        );
      }

      final next = upcoming.first;
      final start = next.startAt!;
      final date = '${start.day}/${start.month}/${start.year} · '
          '${TimeOfDay.fromDateTime(start).format(context)}';
      return _AppointmentSummaryCard(
        title: next.status == 'pending' ? 'Request awaiting confirmation' : 'Next appointment',
        detail: '${next.sessionType.replaceAll('_', ' ')} · $date',
        icon: next.status == 'pending'
            ? Icons.hourglass_top_rounded
            : Icons.event_available_outlined,
        onTap: () => setState(() => _selectedTabIndex = 1),
      );
    },
  );

  Widget _buildGreetingBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF044E38), Color(0xFF065F46), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _emeraldGreen.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Alias: $_activePseudonym',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.spa_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Your wellbeing matters.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Safe, anonymous support is always within your reach.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// "How are you feeling today?" mood emoji selector
  Widget _buildMoodSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Icon(
                Icons.insights_rounded,
                size: 18,
                color: _emeraldGreen,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your mood for private wellbeing insights',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (index) {
              final mood = _moods[index];
              final isSelected = _selectedMoodIndex == index;

              return GestureDetector(
                onTap: () => _onMoodSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _mintTint : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? _emeraldGreen : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _emeraldGreen.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? _darkEmerald
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Quick Action cards: "Book Counselor", "My Schedule", "Privacy Settings"
  Widget _buildQuickActionCards() {
    return Row(
      children: [
        Expanded(
          child: _quickActionTile(
            title: 'Book\nCounselor',
            icon: Icons.calendar_month_rounded,
            color: _emeraldGreen,
            bgColor: _mintTint,
            onTap: _navigateToCounselorDirectory,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionTile(
            title: 'My\nSchedule',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFF0F9FF),
            onTap: () => setState(() => _selectedTabIndex = 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionTile(
            title: 'Privacy\nSettings',
            icon: Icons.security_rounded,
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
            onTap: _navigateToPrivacySettings,
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Recommended Counselors list with "Book Now" shortcuts
  Widget _buildRecommendedCounselorsList() {
    if (_isLoadingCounselors) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: _emeraldGreen),
      );
    }

    if (_recommendedCounselors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No counselors currently available.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _recommendedCounselors.map((counselor) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 52,
                  height: 52,
                  color: _mintTint,
                  child: counselor.image.isNotEmpty
                      ? Image.network(
                          counselor.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _avatarFallback(counselor.name),
                        )
                      : _avatarFallback(counselor.name),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counselor.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      counselor.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          counselor.rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (counselor.isConfidentialSupported)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _mintTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Confidential',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _emeraldGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // "Book Now" shortcut button
              FilledButton(
                onPressed: () => _navigateToBooking(counselor),
                style: FilledButton.styleFrom(
                  backgroundColor: _emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Book Now'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Schedule View tab content with full CRUD and anonymity indicators
  Widget _buildScheduleView() {
    return StudentAppointmentsScreen(service: _appointmentService);
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _emeraldGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'MC';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _emeraldGreen,
        ),
      ),
    );
  }

  /// Bottom Navigation Bar (Home, Schedule, Counselors, Mood Log)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: _mintTint,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: _emeraldGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon:
                Icon(Icons.calendar_month_rounded, color: _emeraldGreen),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon:
                Icon(Icons.people_alt_rounded, color: _emeraldGreen),
            label: 'Counselors',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood_outlined),
            selectedIcon: Icon(Icons.mood_rounded, color: _emeraldGreen),
            label: 'Mood Log',
          ),
        ],
      ),
    );
  }
}

class _MoodItem {
  const _MoodItem(this.emoji, this.label);
  final String emoji;
  final String label;
}

class _AppointmentSummaryCard extends StatelessWidget {
  const _AppointmentSummaryCard({
    required this.title,
    required this.detail,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback? onTap;

  static const Color _green = Color(0xFF059669);
  static const Color _mint = Color(0xFFECFDF5);

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: _mint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(detail, style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    ),
  );
}
