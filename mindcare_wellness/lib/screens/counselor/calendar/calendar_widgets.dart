import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';
import '../../../widgets/auth_widgets.dart';

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});
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
            Icons.calendar_month_outlined,
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
                'Calendar',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD6F8DE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Synced just now',
            style: TextStyle(
              color: dashboardGreen,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 18,
          backgroundColor: mintGreen,
          child: Icon(Icons.person, color: dashboardGreen),
        ),
      ],
    ),
  );
}

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final offset = firstDay.weekday % 7;
    final days = DateTime(now.year, now.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.chevron_left, color: Colors.blueGrey, size: 18),
              const Spacer(),
              Text(
                '${monthName(now.month)} ${now.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.blueGrey, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'S',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'M',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'T',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'W',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'T',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'F',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'S',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 22,
            ),
            itemBuilder: (context, index) {
              final number = index - offset + 1;
              if (number < 1 || number > days) return const SizedBox();
              final selected = number == now.day;
              return Center(
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? dashboardGreen : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: selected ? Colors.white : dashboardInk,
                      fontSize: 8,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CalendarBooking extends StatelessWidget {
  const CalendarBooking({
    required this.time,
    required this.student,
    required this.topic,
    required this.tag,
    required this.status,
    required this.color,
    required this.action,
    super.key,
  });
  final String time, student, topic, tag, status, action;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: color, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            CalendarStatus(text: status, urgent: status == 'HIGH PRIORITY'),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          student,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        Text(
          'Topic: $topic',
          style: const TextStyle(color: Colors.blueGrey, fontSize: 8),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(child: CalendarChip(text: tag)),
            const SizedBox(width: 5),
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dashboardGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
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

class DataCalendarBooking extends StatelessWidget {
  const DataCalendarBooking({required this.item, super.key});
  final CounselorAppointment item;
  @override
  Widget build(BuildContext context) => CalendarBooking(
    time: appointmentTime(item.startAt),
    student: item.studentId.isEmpty
        ? 'Student appointment'
        : 'Student #${shortStudentId(item.studentId)}',
    topic: item.sessionType,
    tag: item.sessionType,
    status: item.status == 'confirmed' ? 'Upcoming' : 'PENDING',
    color: item.status == 'confirmed' ? dashboardGreen : Colors.orange,
    action: item.status == 'pending' ? 'Review →' : 'View →',
  );
}

class CalendarStatus extends StatelessWidget {
  const CalendarStatus({required this.text, this.urgent = false, super.key});
  final String text;
  final bool urgent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: urgent ? Colors.red.shade700 : const Color(0xFFD9F7E1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: urgent ? Colors.white : dashboardGreen,
        fontSize: 7,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class CalendarChip extends StatelessWidget {
  const CalendarChip({required this.text, super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE1F7E8),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: dashboardGreen,
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class OpenSlot extends StatelessWidget {
  const OpenSlot({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFD9F9E4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.add_circle_outline,
          color: Color(0xFF72D994),
          size: 17,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '11:45 - 12:30\nUnallocated Slot',
            style: TextStyle(fontSize: 9, height: 1.35),
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: dashboardGreen,
            side: const BorderSide(color: dashboardGreen),
            minimumSize: const Size(52, 25),
            padding: EdgeInsets.zero,
          ),
          child: const Text('+ Book', style: TextStyle(fontSize: 8)),
        ),
      ],
    ),
  );
}

class LunchBreak extends StatelessWidget {
  const LunchBreak({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6F3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Icon(Icons.schedule, color: Colors.blueGrey, size: 14),
        SizedBox(width: 8),
        Text(
          '12:30 - 13:30   Lunch Break',
          style: TextStyle(color: Colors.blueGrey, fontSize: 9),
        ),
      ],
    ),
  );
}
