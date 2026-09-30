import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/auth_widgets.dart';
import '../counselor_theme.dart';

class CounselorReportsScreen extends StatelessWidget {
  const CounselorReportsScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<List<CounselorAppointment>>(
      stream: service.appointments(),
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? const <CounselorAppointment>[];
        final sessions = appointments
            .where(
              (item) =>
                  item.status == 'confirmed' || item.status == 'completed',
            )
            .length;
        final noShows = appointments
            .where(
              (item) => item.status == 'no-show' || item.status == 'missed',
            )
            .length;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const ReportsHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workload, Attendance & Wellbeing\nAnalytics',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Sep 14 - Sep 20, 2026 • Fall Semester Midterms',
                          style: TextStyle(
                            color: dashboardGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const WeekSelector(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Weekly Overview',
                    style: TextStyle(
                      color: dashboardInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Sessions Held',
                          value: '$sessions',
                          icon: Icons.groups_2_outlined,
                          foot: '↑ +12% vs last wk',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricCard(
                          label: 'No-Shows',
                          value: '$noShows',
                          icon: Icons.block_outlined,
                          foot: 'Rate: 8.5%',
                          badge: 'Low',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: MetricCard(
                          label: 'Rescheduled',
                          value: '4',
                          icon: Icons.sync_rounded,
                          foot: '✓ Auto-synced',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: MetricCard(
                          label: 'Avg Mood',
                          value: '3.4',
                          suffix: '/5.0',
                          icon: Icons.sentiment_satisfied_alt_outlined,
                          foot: '↗ Stabilizing',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SessionsChart(total: sessions == 0 ? 18 : sessions),
                  const SizedBox(height: 12),
                  const UtilizationCard(),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: dashboardMint,
    padding: const EdgeInsets.fromLTRB(18, 12, 17, 13),
    child: Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: const Color(0xFFD5F8DF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.bar_chart_outlined,
            color: dashboardGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COUNSELOR PORTAL',
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              Text(
                'Reports',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: mintGreen,
          child: Icon(Icons.person, color: dashboardGreen),
        ),
      ],
    ),
  );
}

class WeekSelector extends StatelessWidget {
  const WeekSelector({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF9BDEB0)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: dashboardGreen),
        SizedBox(width: 6),
        Text(
          'This\nWeek',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
        SizedBox(width: 8),
        Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.blueGrey),
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.foot,
    this.suffix,
    this.badge,
    super.key,
  });
  final String label, value, foot;
  final IconData icon;
  final String? suffix, badge;
  @override
  Widget build(BuildContext context) => Container(
    height: 93,
    padding: const EdgeInsets.fromLTRB(11, 10, 10, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFD7F1DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
              ),
            ),
            Icon(icon, color: dashboardGreen, size: 15),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: dashboardInk,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              foot,
              style: const TextStyle(
                color: dashboardGreen,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F7E1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: dashboardGreen,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class SessionsChart extends StatelessWidget {
  const SessionsChart({required this.total, super.key});
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD7F1DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sessions Overview',
          style: TextStyle(
            color: dashboardInk,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Daily clinical appointments distribution',
          style: TextStyle(color: Colors.blueGrey, fontSize: 9),
        ),
        const SizedBox(height: 17),
        const SizedBox(
          height: 115,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReportBar(day: 'Mon', value: 4, height: 54),
              _ReportBar(day: 'Tue', value: 6, height: 78, peak: true),
              _ReportBar(day: 'Wed', value: 3, height: 40),
              _ReportBar(day: 'Thu', value: 4, height: 54),
              _ReportBar(day: 'Fri', value: 2, height: 28, bright: true),
            ],
          ),
        ),
        const Divider(height: 15),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: dashboardGreen,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Total $total slots fulfilled • 92% counselor utilization',
                style: const TextStyle(color: dashboardInk, fontSize: 9),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F7E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8AE4A8)),
              ),
              child: const Text(
                'Healthy',
                style: TextStyle(
                  color: dashboardGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReportBar extends StatelessWidget {
  const _ReportBar({
    required this.day,
    required this.value,
    required this.height,
    this.peak = false,
    this.bright = false,
  });
  final String day;
  final int value;
  final double height;
  final bool peak, bright;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (peak)
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: dashboardGreen,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'Peak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      Text('$value', style: const TextStyle(color: dashboardInk, fontSize: 9)),
      const SizedBox(height: 3),
      Container(
        width: 21,
        height: height,
        decoration: BoxDecoration(
          color: bright
              ? dashboardBright
              : (peak ? const Color(0xFF10D51A) : dashboardGreen),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        day,
        style: TextStyle(
          color: peak ? dashboardGreen : Colors.blueGrey,
          fontSize: 9,
          fontWeight: peak ? FontWeight.w800 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class UtilizationCard extends StatelessWidget {
  const UtilizationCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE1FBEA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF9BE9B4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: dashboardGreen, size: 16),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Total 18 slots fulfilled • 92% counselor utilization',
            style: TextStyle(color: dashboardInk, fontSize: 9),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8AE4A8)),
          ),
          child: const Text(
            'Healthy',
            style: TextStyle(
              color: dashboardGreen,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
