import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';
import '../appointment_details_screen.dart';
import '../calendar/counselor_calendar_screen.dart';
import '../notifications/counselor_notifications_screen.dart';
import '../notes/counselor_notes_screen.dart';

class CounselorHomeScreen extends StatelessWidget {
  const CounselorHomeScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(
    future: service.getProfile(),
    builder: (context, profileSnapshot) {
      if (profileSnapshot.connectionState == ConnectionState.waiting) {
        return const LoadingWidget();
      }
      if (profileSnapshot.hasError || profileSnapshot.data == null) {
        return const ErrorMessage(
          message: 'We could not load your counselor dashboard.',
        );
      }
      return StreamBuilder<List<CounselorAppointment>>(
        stream: service.appointments(),
        builder: (context, appointmentSnapshot) {
          final appointments =
              appointmentSnapshot.data ?? const <CounselorAppointment>[];
          final upcoming =
              appointments
                  .where(
                    (item) =>
                        (item.status == 'pending' ||
                            item.status == 'confirmed') &&
                        (item.startAt?.isAfter(DateTime.now()) ?? false),
                  )
                  .toList()
                ..sort(
                  (a, b) => (a.startAt ?? DateTime(2100)).compareTo(
                    b.startAt ?? DateTime(2100),
                  ),
                );
          final today = todayAppointments(appointments);
          final remaining = today
              .where((item) => upcoming.isEmpty || item.id != upcoming.first.id)
              .toList();
          final pendingCount = appointments
              .where((item) => item.status == 'pending')
              .length;
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: service.getProfile,
              color: dashboardGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 10, 17, 28),
                children: [
                  _DashboardHeader(profile: profileSnapshot.data!),
                  const SizedBox(height: 6),
                  _DateLine(date: DateTime.now()),
                  const SizedBox(height: 5),
                  Text(
                    '${_greeting()}, ${profileSnapshot.data!.name}',
                    style: const TextStyle(
                      color: dashboardInk,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DashboardSummary(
                    todayCount: today.length,
                    pendingCount: pendingCount,
                    upcomingCount: upcoming.length,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Next appointment'),
                  const SizedBox(height: 9),
                  if (upcoming.isEmpty)
                    const _EmptyNextAppointment()
                  else
                    _NextAppointmentCard(
                      item: upcoming.first,
                      service: service,
                    ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Remaining bookings today'),
                  const SizedBox(height: 10),
                  if (remaining.isEmpty)
                    const EmptyState(
                      message: 'No other appointments scheduled for today.',
                    )
                  else
                    ...remaining.map(
                      (item) => _AppointmentRow(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentDetailsScreen(
                              item: item,
                              service: service,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Main actions'),
                  const SizedBox(height: 10),
                  _ActionGrid(
                    onCalendar: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: dashboardMint,
                          body: CounselorCalendarScreen(service: service),
                        ),
                      ),
                    ),
                    onNotes: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: dashboardMint,
                          body: CounselorNotesScreen(service: service),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _greeting() {
  final hour = DateTime.now().hour;
  return hour < 12
      ? 'Good morning'
      : hour < 18
      ? 'Good afternoon'
      : 'Good evening';
}

class _DateLine extends StatelessWidget {
  const _DateLine({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.calendar_today_outlined,
        size: 13,
        color: dashboardGreen,
      ),
      const SizedBox(width: 6),
      Text(
        '${weekdayName(date.weekday).substring(0, 1)}${weekdayName(date.weekday).substring(1).toLowerCase()}, ${date.day} ${monthName(date.month).substring(0, 1)}${monthName(date.month).substring(1).toLowerCase()} ${date.year}',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({
    required this.todayCount,
    required this.pendingCount,
    required this.upcomingCount,
  });
  final int todayCount;
  final int pendingCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _SummaryBox(
          icon: Icons.event_available_outlined,
          value: todayCount,
          label: 'TODAY\nScheduled',
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _SummaryBox(
          icon: Icons.pending_actions_outlined,
          value: pendingCount,
          label: 'PENDING\nRequests',
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _SummaryBox(
          icon: Icons.upcoming_outlined,
          value: upcomingCount,
          label: 'UPCOMING\nSessions',
        ),
      ),
    ],
  );
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 82,
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF8E6),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Icon(icon, color: dashboardGreen, size: 19),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 9,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile});
  final CounselorProfile profile;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 23,
        backgroundColor: dashboardMint,
        backgroundImage: profile.imageUrl == null
            ? null
            : NetworkImage(profile.imageUrl!),
        child: profile.imageUrl == null
            ? const Icon(Icons.person, color: dashboardGreen)
            : null,
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'COUNSELOR PORTAL',
          style: TextStyle(
            color: dashboardGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
      ),
      StreamBuilder(
        stream: NotificationService().mine(),
        builder: (context, snapshot) {
          final unread = (snapshot.data ?? [])
              .where((item) => !item.isRead)
              .length;
          return Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CounselorNotificationsScreen(),
                  ),
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: dashboardInk,
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: dashboardInk,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _EmptyNextAppointment extends StatelessWidget {
  const _EmptyNextAppointment();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.event_available_outlined, color: dashboardGreen, size: 30),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'No upcoming appointments. Your schedule is clear.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.item, required this.service});
  final CounselorAppointment item;
  final CounselorService service;
  @override
  Widget build(BuildContext context) {
    final isPriority =
        item.data['priority'] == 'high' || item.data['isHighPriority'] == true;
    final mode = item.location?.isNotEmpty == true
        ? item.location!
        : item.sessionType;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: dashboardGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22087517),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT APPOINTMENT',
            style: TextStyle(
              color: dashboardBright,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _CardChip(
                  icon: Icons.schedule,
                  label:
                      '${appointmentTime(item.startAt)} - ${item.endAt == null ? 'TBD' : appointmentTime(item.endAt)}',
                ),
              ),
              if (isPriority) ...[
                const SizedBox(width: 7),
                const _PriorityChip(),
              ],
            ],
          ),
          const SizedBox(height: 13),
          Text(
            item.studentAlias,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.reason,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            item.sessionType,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.place_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mode,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetailsScreen(
                        item: item,
                        service: service,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: dashboardBright,
                    foregroundColor: dashboardInk,
                  ),
                  child: const Text('View appointment'),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(item.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: dashboardBright,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: dashboardInk, size: 12),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dashboardInk,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text(
      'HIGH PRIORITY',
      style: TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == 'confirmed' ? Icons.check_circle_outline : Icons.schedule,
          size: 15,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          appointmentStatusLabel(status),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.onCalendar, required this.onNotes});
  final VoidCallback onCalendar;
  final VoidCallback onNotes;
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 2.45,
    children: [
      _ActionTile(
        icon: Icons.calendar_month_outlined,
        title: 'Calendar',
        subtitle: 'Manage schedule',
        onTap: onCalendar,
      ),
      _ActionTile(
        icon: Icons.pending_actions_outlined,
        title: 'Requests',
        subtitle: 'Review bookings',
        onTap: onCalendar,
      ),
      _ActionTile(
        icon: Icons.schedule_outlined,
        title: 'Availability',
        subtitle: 'Set working hours',
        onTap: onCalendar,
      ),
      _ActionTile(
        icon: Icons.chat_bubble_outline,
        title: 'Messages',
        subtitle: 'Open conversations',
        onTap: onNotes,
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: dashboardGreen, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: dashboardInk,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.item, required this.onTap});
  final CounselorAppointment item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              appointmentTime(item.startAt),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: dashboardGreen,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentAlias,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dashboardInk,
                  ),
                ),
                Text(
                  item.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  item.location?.isNotEmpty == true
                      ? '${item.sessionType} · ${item.location}'
                      : item.sessionType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.status == 'confirmed'
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                size: 15,
                color: item.status == 'confirmed'
                    ? dashboardGreen
                    : Colors.orange,
              ),
              const SizedBox(width: 3),
              Text(
                appointmentStatusLabel(item.status),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
