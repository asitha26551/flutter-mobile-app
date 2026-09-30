import 'package:flutter/material.dart';

import '../../../models/counselor_availability_model.dart';
import '../../../models/counselor_models.dart';
import '../../../services/availability_service.dart';
import '../../../services/counselor_service.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/common/loading.dart';
import '../appointment_details_screen.dart';
import '../counselor_helpers.dart';
import '../counselor_theme.dart';

class CounselorCalendarScreen extends StatefulWidget {
  const CounselorCalendarScreen({required this.service, super.key});
  final CounselorService service;

  @override
  State<CounselorCalendarScreen> createState() =>
      _CounselorCalendarScreenState();
}

class _CounselorCalendarScreenState extends State<CounselorCalendarScreen> {
  final availabilityService = AvailabilityService();
  late DateTime month;
  late DateTime selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = DateTime.now();
    month = DateTime(selectedDay.year, selectedDay.month);
  }

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.15,
    child: SafeArea(
      child: StreamBuilder<List<CounselorAppointment>>(
        stream: widget.service.appointments(),
        builder: (context, appointmentSnapshot) {
          if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
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
          return StreamBuilder<List<CounselorAvailabilityModel>>(
            stream: availabilityService.forCounselor(availabilityService.uid),
            builder: (context, availabilitySnapshot) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 28),
              children: [
                const _CalendarHeading(),
                const SizedBox(height: 14),
                _MonthCard(
                  month: month,
                  selectedDay: selectedDay,
                  appointments: appointments,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onDaySelected: (day) => setState(() => selectedDay = day),
                ),
                const SizedBox(height: 18),
                Text(
                  _dateLabel(selectedDay),
                  style: const TextStyle(
                    color: dashboardInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                if (selected.isEmpty)
                  const _CalendarEmpty(message: 'No appointments on this day.')
                else
                  ...selected.map(
                    (item) => _CalendarAppointment(
                      item: item,
                      onTap: () => Navigator.push(
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
                const SizedBox(height: 17),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Working hours',
                        style: TextStyle(
                          color: dashboardInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add availability',
                      onPressed: () => _addAvailability(context),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: dashboardGreen,
                      ),
                    ),
                  ],
                ),
                if (availabilitySnapshot.hasError)
                  const _CalendarEmpty(
                    message: 'Availability is unavailable right now.',
                  )
                else if ((availabilitySnapshot.data ?? []).isEmpty)
                  const _CalendarEmpty(message: 'No working hours configured.')
                else
                  ...availabilitySnapshot.data!.map(
                    (item) => _AvailabilityRow(
                      item: item,
                      onDelete: () => availabilityService.delete(item.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  void _changeMonth(int offset) => setState(() {
    month = DateTime(month.year, month.month + offset);
    selectedDay = DateTime(month.year, month.month, 1);
  });

  Future<void> _addAvailability(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AddAvailabilityDialog(
        dayOfWeek: weekdayName(selectedDay.weekday),
        service: availabilityService,
      ),
    );
    if (result == true && mounted) setState(() {});
  }
}

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
String _dateLabel(DateTime date) =>
    '${weekdayName(date.weekday).substring(0, 1)}${weekdayName(date.weekday).substring(1).toLowerCase()}, ${date.day} ${monthName(date.month).substring(0, 1)}${monthName(date.month).substring(1).toLowerCase()}';

class _CalendarHeading extends StatelessWidget {
  const _CalendarHeading();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.calendar_month_outlined,
        color: dashboardGreen,
        size: 28,
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
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
            Text(
              'Calendar',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD8F8E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Live sync',
          style: TextStyle(
            color: dashboardGreen,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
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
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
  });
  final DateTime month;
  final DateTime selectedDay;
  final List<CounselorAppointment> appointments;
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
              final hasAppointment = appointments.any(
                (item) => _sameDay(item.startAt, date),
              );
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
                    if (hasAppointment)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
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

class _CalendarAppointment extends StatelessWidget {
  const _CalendarAppointment({required this.item, required this.onTap});
  final CounselorAppointment item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final statusColor = item.status == 'pending'
        ? Colors.orange.shade800
        : dashboardGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 75,
              child: Text(
                appointmentTime(item.startAt),
                style: const TextStyle(
                  color: dashboardGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reason,
                    style: const TextStyle(
                      color: dashboardInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.studentAlias,
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              appointmentStatusLabel(item.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.item, required this.onDelete});
  final CounselorAvailabilityModel item;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule_outlined, color: dashboardGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${item.dayOfWeek}  ${item.startTime} - ${item.endTime}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: dashboardInk,
            ),
          ),
        ),
        Text(
          '${item.sessionDuration} min',
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
        IconButton(
          tooltip: 'Delete working hours',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 19),
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
