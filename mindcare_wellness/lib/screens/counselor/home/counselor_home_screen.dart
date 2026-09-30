import 'package:flutter/material.dart';

import '../../../models/counselor_models.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';
import 'home_widgets.dart';

class CounselorHomeScreen extends StatelessWidget {
  const CounselorHomeScreen({required this.service, super.key});
  final CounselorService service;

  @override
  Widget build(BuildContext context) => FutureBuilder<CounselorProfile>(
    future: service.getProfile(),
    builder: (context, profileSnapshot) {
      if (profileSnapshot.connectionState == ConnectionState.waiting)
        return const LoadingWidget();
      if (profileSnapshot.hasError || profileSnapshot.data == null)
        return const ErrorMessage(
          message: 'We could not load your counselor dashboard.',
        );
      final profile = profileSnapshot.data!;
      return StreamBuilder<List<CounselorAppointment>>(
        stream: service.appointments(),
        builder: (context, appointmentSnapshot) {
          final appointments =
              appointmentSnapshot.data ?? const <CounselorAppointment>[];
          final todaysAppointments = todayAppointments(appointments);
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: service.getProfile,
              color: dashboardGreen,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  PortalHeader(profile: profile),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DateLine(),
                        const SizedBox(height: 5),
                        Text(
                          'Hi, ${profile.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: dashboardInk,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: DashboardStat(
                                icon: Icons.event_available,
                                value: todaysAppointments.length,
                                label: 'TODAY\nScheduled',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DashboardStat(
                                icon: Icons.event_busy_outlined,
                                value: appointments
                                    .where((item) => item.status == 'rejected')
                                    .length,
                                label: 'NO-SHOW\nThis Week',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: DashboardStat(
                                icon: Icons.edit_note_outlined,
                                value: 3,
                                label: 'PENDING\nClinical Notes',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const SectionHeading('Upcoming Booking Today'),
                        const SizedBox(height: 9),
                        if (todaysAppointments.isEmpty)
                          const EmptyState(
                            message: 'No appointments scheduled for today.',
                          )
                        else ...[
                          FeaturedAppointment(
                            item: todaysAppointments.first,
                            service: service,
                          ),
                          if (todaysAppointments.length > 1) ...[
                            const SizedBox(height: 20),
                            const SectionHeading('Remaining Bookings Today'),
                            const SizedBox(height: 9),
                            ...todaysAppointments
                                .skip(1)
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: CompactAppointment(item: item),
                                  ),
                                ),
                          ],
                        ],
                      ],
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
