import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';

class PortalHeader extends StatelessWidget {
  const PortalHeader({required this.profile, super.key});
  final CounselorProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    color: dashboardMint,
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: dashboardGreen,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
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
                  letterSpacing: .7,
                ),
              ),
              Text(
                'Home',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFDDF8E6),
          backgroundImage: profile.imageUrl == null
              ? null
              : NetworkImage(profile.imageUrl!),
          child: profile.imageUrl == null
              ? const Icon(Icons.person, color: dashboardGreen, size: 22)
              : null,
        ),
      ],
    ),
  );
}

class DateLine extends StatelessWidget {
  const DateLine({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: dashboardGreen,
        ),
        const SizedBox(width: 5),
        Text(
          '${weekdayName(now.weekday)}, ${now.day} ${monthName(now.month)} ${now.year}',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
      ],
    );
  }
}

class DashboardStat extends StatelessWidget {
  const DashboardStat({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });
  final IconData icon;
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 91,
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFDFF9E8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: const BoxDecoration(
            color: Color(0xFFC9F2D5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: dashboardGreen),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 9,
            height: 1.05,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.access_time, size: 16, color: dashboardGreen),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: dashboardInk,
        ),
      ),
    ],
  );
}

class FeaturedAppointment extends StatelessWidget {
  const FeaturedAppointment({
    required this.item,
    required this.service,
    super.key,
  });
  final CounselorAppointment item;
  final CounselorService service;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
    decoration: BoxDecoration(
      color: dashboardGreen,
      borderRadius: BorderRadius.circular(11),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33087517),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Tag(
                icon: Icons.circle,
                text: 'In-Person · ${appointmentTime(item.startAt)}',
                color: dashboardBright,
              ),
            ),
            const SizedBox(width: 6),
            Tag(text: 'HIGH PRIORITY', color: Colors.red),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Text(
                item.studentId.isEmpty
                    ? 'Student appointment'
                    : 'Student #${shortStudentId(item.studentId)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SoftTag(text: item.sessionType),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Undergraduate · Year 2 · Science Faculty',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: SoftTag(text: '😊 Smiling Check-in')),
            const SizedBox(width: 5),
            const Expanded(
              child: SoftTag(
                text: '▣ Focus: Academic Stress &\n   Midterm Fatigue',
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const DetailLine(
          icon: Icons.location_on_outlined,
          text: 'Room 204 · Mental Health Wing',
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.meeting_room_outlined, size: 16),
            label: const Text('Open Session Workspace'),
            style: FilledButton.styleFrom(
              backgroundColor: dashboardBright,
              foregroundColor: dashboardInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.note_add_outlined, size: 16),
            label: const Text('Quick Review Notes'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (item.status == 'pending')
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => service.updateAppointment(item.id, 'confirmed'),
              child: const Text(
                'Accept request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );
}

class CompactAppointment extends StatelessWidget {
  const CompactAppointment({required this.item, super.key});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${appointmentTime(item.startAt)}  ·  ${item.sessionType}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            StatusPill(item.status),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          item.studentId.isEmpty
              ? 'Student appointment'
              : 'Student #${shortStudentId(item.studentId)}',
          style: const TextStyle(
            color: dashboardInk,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.sessionType,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
        const SizedBox(height: 7),
        const Row(
          children: [
            Expanded(child: SoftTag(text: 'Smiling Check-in', light: true)),
            SizedBox(width: 5),
            Expanded(
              child: SoftTag(text: 'Encrypted Audio Session', light: true),
            ),
          ],
        ),
      ],
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag({this.icon, required this.text, required this.color, super.key});
  final IconData? icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 8, color: dashboardInk),
        if (icon != null) const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: dashboardInk,
          ),
        ),
      ],
    ),
  );
}

class SoftTag extends StatelessWidget {
  const SoftTag({required this.text, this.light = false, super.key});
  final String text;
  final bool light;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: light ? const Color(0xFFDDF5E5) : Colors.white24,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: light ? dashboardGreen : Colors.white,
        fontSize: 9,
        height: 1.1,
      ),
    ),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: dashboardBright,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      status.toUpperCase(),
      style: const TextStyle(
        color: dashboardInk,
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
