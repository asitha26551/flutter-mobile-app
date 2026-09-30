import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import 'calendar_widgets.dart';

class CounselorCalendarScreen extends StatelessWidget {
  const CounselorCalendarScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<List<CounselorAppointment>>(
      stream: service.appointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingWidget();
        if (snapshot.hasError)
          return const ErrorMessage(
            message: 'Appointments are unavailable right now.',
          );
        final appointments = snapshot.data ?? const <CounselorAppointment>[];
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const CalendarHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MonthCalendar(),
                  const SizedBox(height: 15),
                  const Text(
                    'Tue 15',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Time Slots (5 Total)',
                    style: TextStyle(color: Colors.black54, fontSize: 9),
                  ),
                  const SizedBox(height: 9),
                  if (appointments.isEmpty) ...const [
                    CalendarBooking(
                      time: '09:30 - 10:15',
                      student: 'Student #4821',
                      topic: 'Academic Stress & Midterm Fatigue',
                      tag: 'In-Person',
                      status: 'HIGH PRIORITY',
                      color: Color(0xFF087A17),
                      action: 'View →',
                    ),
                    CalendarBooking(
                      time: '10:15 - 11:00',
                      student: 'Student #1190',
                      topic: 'Anxiety about study performance',
                      tag: 'Voice Call',
                      status: 'Live Next',
                      color: Color(0xFF087A17),
                      action: 'Join →',
                    ),
                    CalendarBooking(
                      time: '11:00 - 11:45',
                      student: 'Student #7734',
                      topic: 'General Routine Check-in',
                      tag: 'In-Person Room 2B',
                      status: 'Missed Check-in',
                      color: Colors.orange,
                      action: 'Dispatch Follow-up',
                    ),
                  ] else
                    ...appointments
                        .take(5)
                        .map((item) => DataCalendarBooking(item: item)),
                  const OpenSlot(),
                  const LunchBreak(),
                  const CalendarBooking(
                    time: '13:30 - 14:15',
                    student: 'Student #0552',
                    topic: 'Sleep Hygiene & Exhaustion concerns',
                    tag: 'Encrypted Chat',
                    status: 'Upcoming',
                    color: Color(0xFF087A17),
                    action: 'Prepare Chat',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
