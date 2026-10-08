import 'package:flutter/material.dart';

import '../../../models/counselor_availability_model.dart';
import '../../../models/counselor_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/availability_service.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../appointment_details_screen.dart';
import '../counselor_page_header.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';
import 'counselor_availability_screen.dart';

class CounselorCalendarScreen extends StatefulWidget {
  const CounselorCalendarScreen({
    required this.service,
    required this.authService,
    required this.onSync,
    required this.syncing,
    super.key,
  });
  final CounselorService service;
  final AuthService authService;
  final Future<void> Function() onSync;
  final bool syncing;

  @override
  State<CounselorCalendarScreen> createState() =>
      _CounselorCalendarScreenState();
}

class _CounselorCalendarScreenState extends State<CounselorCalendarScreen> {
  late DateTime month;
  late DateTime selectedDay;
  final availabilityService = AvailabilityService();
  late final Stream<List<CounselorAppointment>> _appointmentsStream;
  late final Stream<List<CounselorAvailabilityModel>> _availabilityStream;
  String selectedStatus = 'confirmed';

  @override
  void initState() {
    super.initState();
    selectedDay = DateTime.now();
    month = DateTime(selectedDay.year, selectedDay.month);
    _appointmentsStream = widget.service.appointments();
    _availabilityStream = availabilityService.forCounselor(availabilityService.uid);
  }

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.15,
    child: SafeArea(
      child: StreamBuilder<List<CounselorAppointment>>(
        stream: _appointmentsStream,
        builder: (context, appointmentSnapshot) {
          if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading your calendar…');
          }
          if (appointmentSnapshot.hasError) {
            return const ErrorMessage(
              message: 'Appointments are unavailable right now.',
            );
          }
          final appointments =
              appointmentSnapshot.data ?? const <CounselorAppointment>[];
          final selected =
              appointments
                  .where((item) => _sameDay(item.startAt, selectedDay))
                  .toList()
                ..sort(
                  (a, b) => (a.startAt ?? DateTime(2100)).compareTo(
                    b.startAt ?? DateTime(2100),
                  ),
                );
          final visibleAppointments = selected.where((item) {
            if (selectedStatus == 'confirmed') {
              return item.status == 'confirmed' ||
                  item.status == 'rescheduled' ||
                  item.status == 'completed' ||
                  item.status == 'no_show';
            }
            return item.status == selectedStatus;
          }).toList();
          return StreamBuilder<List<CounselorAvailabilityModel>>(
            stream: _availabilityStream,
            builder: (context, availabilitySnapshot) {
              final availability = availabilitySnapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 28),
            children: [
              CounselorPageHeader(
                title: 'Calendar',
                service: widget.service,
                authService: widget.authService,
                onSync: widget.onSync,
                syncing: widget.syncing,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openAvailability,
                  icon: const Icon(Icons.schedule_outlined, size: 18),
                  label: const Text('Manage availability'),
                  style: TextButton.styleFrom(foregroundColor: dashboardGreen),
                ),
              ),
              const SizedBox(height: 6),
              _MonthCard(
                month: month,
                selectedDay: selectedDay,
                appointments: appointments,
                availability: availability,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
                onDaySelected: (day) => setState(() => selectedDay = day),
              ),
              const SizedBox(height: 10),
              const _CalendarLegend(),
              const SizedBox(height: 18),
              Text(
                _dateLabel(selectedDay),
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              _AppointmentStatusTabs(
                selectedStatus: selectedStatus,
                appointments: selected,
                onChanged: (status) => setState(() => selectedStatus = status),
              ),
              const SizedBox(height: 8),
              if (visibleAppointments.isEmpty)
                const _CalendarEmpty(message: 'No appointments on this day.')
              else
                ...[
                  _AppointmentSectionHeader(
                    label: _statusLabel(selectedStatus),
                    count: visibleAppointments.length,
                    color: _statusColor(selectedStatus),
                  ),
                  ...visibleAppointments.map(
                      (item) => _CalendarAppointment(
                        item: item,
                        onView: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentDetailsScreen(
                              item: item,
                              service: widget.service,
                            ),
                          ),
                        ),
                      ),
                  ),
                ],
            ],
          );
            },
          );
        },
      ),
    ),
  );

  void _changeMonth(int offset) => setState(() {
    month = DateTime(month.year, month.month + offset);
    selectedDay = DateTime(month.year, month.month, 1);
  });

  Future<void> _openAvailability() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: dashboardMint,
          body: const CounselorAvailabilityScreen(),
        ),
      ),
    );
  }

}

class _AppointmentStatusTabs extends StatelessWidget {
  const _AppointmentStatusTabs({
    required this.selectedStatus,
    required this.appointments,
    required this.onChanged,
  });
  final String selectedStatus;
  final List<CounselorAppointment> appointments;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF9EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _StatusTab(
          label: 'Confirmed',
          count: appointments
              .where(
                (item) =>
                    item.status == 'confirmed' ||
                    item.status == 'rescheduled' ||
                    item.status == 'completed' ||
                    item.status == 'no_show',
              )
              .length,
          color: dashboardGreen,
          selected: selectedStatus == 'confirmed',
          onTap: () => onChanged('confirmed'),
        ),
        _StatusTab(
          label: 'Pending',
          count: appointments
              .where((item) => item.status == 'pending')
              .length,
          color: Colors.orange.shade700,
          selected: selectedStatus == 'pending',
          onTap: () => onChanged('pending'),
        ),
        _StatusTab(
          label: 'Rejected',
          count: appointments
              .where((item) => item.status == 'rejected')
              .length,
          color: const Color(0xFFC62828),
          selected: selectedStatus == 'rejected',
          onTap: () => onChanged('rejected'),
        ),
      ],
    ),
  );
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x12000000), blurRadius: 4)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                color: selected ? color : Colors.black45,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _statusLabel(String value) => switch (value) {
  'confirmed' => 'Confirmed',
  'pending' => 'Pending',
  'rejected' => 'Rejected',
  _ => 'Appointments',
};

Color _statusColor(String value) => switch (value) {
  'pending' => Colors.orange.shade700,
  'rejected' => const Color(0xFFC62828),
  _ => dashboardGreen,
};

class _AddAvailabilityDialog extends StatefulWidget {
  const _AddAvailabilityDialog({
    required this.dayOfWeek,
    required this.service,
  });
  final String dayOfWeek;
  final AvailabilityService service;

  @override
  State<_AddAvailabilityDialog> createState() => _AddAvailabilityDialogState();
}

class _AddAvailabilityDialogState extends State<_AddAvailabilityDialog> {
  late final TextEditingController startController;
  late final TextEditingController endController;
  late final TextEditingController durationController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    startController = TextEditingController(text: '09:00');
    endController = TextEditingController(text: '17:00');
    durationController = TextEditingController(text: '45');
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.service.create(
        dayOfWeek: widget.dayOfWeek,
        startTime: startController.text.trim(),
        endTime: endController.text.trim(),
        sessionDuration: int.tryParse(durationController.text.trim()) ?? 45,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save working hours.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add working hours',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.dayOfWeek,
              style: const TextStyle(
                color: dashboardGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _AvailabilityField(
              controller: startController,
              label: 'Start time',
              icon: Icons.login_outlined,
            ),
            const SizedBox(height: 14),
            _AvailabilityField(
              controller: endController,
              label: 'End time',
              icon: Icons.logout_outlined,
            ),
            const SizedBox(height: 14),
            _AvailabilityField(
              controller: durationController,
              label: 'Session length',
              suffixText: 'minutes',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(saving ? 'Saving' : 'Add hours'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AvailabilityField extends StatelessWidget {
  const _AvailabilityField({
    required this.controller,
    required this.label,
    required this.icon,
    this.suffixText,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? suffixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      suffixText: suffixText,
      filled: true,
      fillColor: const Color(0xFFF4F8F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFD6E5D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFD6E5D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: dashboardGreen, width: 1.4),
      ),
    ),
  );
}

bool _sameDay(DateTime? a, DateTime b) =>
    a != null && a.year == b.year && a.month == b.month && a.day == b.day;

bool _sameWeekday(String value, DateTime date) =>
  value.trim().toLowerCase() == weekdayName(date.weekday).toLowerCase();

bool _hasCalendarMarker(String status) =>
    status == 'confirmed' ||
    status == 'rescheduled' ||
    status == 'completed' ||
    status == 'pending';

Color _calendarMarkerColor(String status) =>
    status == 'pending'
    ? Colors.orange
    : dashboardGreen;

String _timeRange(CounselorAppointment item) {
  final start = item.startAt;
  final end = item.endAt;
  if (start == null) return 'Time not set';
  String format(DateTime value) {
    final hour = value.hour == 0 ? 12 : value.hour > 12 ? value.hour - 12 : value.hour;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
  }
  return end == null ? format(start) : '${format(start)} - ${format(end)}';
}

String _sessionTypeLabel(String value) => switch (value) {
  'in_person' => 'In-Person',
  'video' => 'Video',
  'audio' => 'Audio',
  'chat' => 'Chat',
  _ => value,
};

String _dateLabel(DateTime date) =>
    '${weekdayName(date.weekday).substring(0, 1)}${weekdayName(date.weekday).substring(1).toLowerCase()}, ${date.day} ${monthName(date.month).substring(0, 1)}${monthName(date.month).substring(1).toLowerCase()}';

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LegendItem(color: dashboardGreen, label: 'Consults'),
        _LegendItem(color: Colors.orange, label: 'Pending'),
        _LegendItem(color: Color(0xFF25B6D2), label: 'Open slots'),
      ],
    ),
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: dashboardInk,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.month,
    required this.selectedDay,
    required this.appointments,
    required this.availability,
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
  });
  final DateTime month;
  final DateTime selectedDay;
  final List<CounselorAppointment> appointments;
  final List<CounselorAvailabilityModel> availability;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;
  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday % 7;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              const Spacer(),
              Text(
                '${monthName(month.month).substring(0, 1)}${monthName(month.month).substring(1).toLowerCase()} ${month.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('S'),
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 38,
            ),
            itemBuilder: (context, index) {
              final day = index - offset + 1;
              if (day < 1 || day > days) return const SizedBox();
              final date = DateTime(month.year, month.month, day);
              final selected = _sameDay(date, selectedDay);
              final markers = <Color>{};
              for (final item in appointments.where(
                (item) =>
                    _sameDay(item.startAt, date) &&
                    _hasCalendarMarker(item.status),
              )) {
                markers.add(_calendarMarkerColor(item.status));
              }
              if (availability.any(
                (item) =>
                    item.isAvailable && _sameWeekday(item.dayOfWeek, date),
              )) {
                markers.add(const Color(0xFF25B6D2));
              }
              return InkWell(
                onTap: () => onDaySelected(date),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? dashboardGreen : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: selected ? Colors.white : dashboardInk,
                          fontSize: 12,
                          height: 1,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (markers.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: markers
                            .map(
                              (color) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppointmentSectionHeader extends StatelessWidget {
  const _AppointmentSectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 7),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: dashboardInk,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count ${count == 1 ? 'appointment' : 'appointments'}',
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    ),
  );
}

class _CalendarAppointment extends StatelessWidget {
  const _CalendarAppointment({required this.item, required this.onView});
  final CounselorAppointment item;
  final VoidCallback onView;
  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'rescheduled' => Colors.orange.shade800,
      'pending' => Colors.orange.shade800,
      _ => dashboardGreen,
    };
    final location = item.location?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _timeRange(item),
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 9),
              _AppointmentChip(
                label: _sessionTypeLabel(item.sessionType),
                color: dashboardGreen,
              ),
              const Spacer(),
              _AppointmentChip(
                label: appointmentStatusLabel(item.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            item.studentAlias,
            style: const TextStyle(
              color: dashboardInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Topic: ${item.reason}',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          const SizedBox(height: 7),
          _MoodLabel(item: item),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE7EFEA)),
          ),
          Row(
            children: [
              Expanded(
                child: _LocationLabel(location: location),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF009B16),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentChip extends StatelessWidget {
  const _AppointmentChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MoodLabel extends StatelessWidget {
  const _MoodLabel({required this.item});
  final CounselorAppointment item;

  @override
  Widget build(BuildContext context) {
    final mood = item.mood?.trim();
    final score = item.moodScore;
    final text = mood == null || mood.isEmpty
        ? 'Mood not recorded'
        : 'Mood: $mood${score == null ? '' : '  •  Score $score/10'}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mood_outlined,
          size: 15,
          color: mood == null || mood.isEmpty ? Colors.black45 : dashboardGreen,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationLabel extends StatelessWidget {
  const _LocationLabel({required this.location});
  final String? location;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF8E6),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on_outlined, color: dashboardGreen, size: 15),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            location?.isNotEmpty == true ? location! : 'Location not set',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dashboardGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CalendarEmpty extends StatelessWidget {
  const _CalendarEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF9EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: dashboardInk,
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
