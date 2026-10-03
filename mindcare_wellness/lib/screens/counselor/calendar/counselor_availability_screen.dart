import 'package:flutter/material.dart';

import '../../../models/counselor_availability_model.dart';
import '../../../services/availability_service.dart';
import '../counselor_theme.dart';

class CounselorAvailabilityScreen extends StatefulWidget {
  const CounselorAvailabilityScreen({super.key});

  @override
  State<CounselorAvailabilityScreen> createState() =>
      _CounselorAvailabilityScreenState();
}

class _CounselorAvailabilityScreenState
    extends State<CounselorAvailabilityScreen> {
  final _service = AvailabilityService();
  String selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.15,
    child: SafeArea(
      child: StreamBuilder<List<CounselorAvailabilityModel>>(
        stream: _service.forCounselor(_service.uid),
        builder: (context, snapshot) {
          final items = [...snapshot.data ?? const <CounselorAvailabilityModel>[]]
            ..sort(_compareAvailability);
          final selectedItems = items
              .where((item) => item.dayOfWeek.toLowerCase() == selectedDay.toLowerCase())
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _AvailabilityHeader(
                onBack: () => Navigator.pop(context),
                onAdd: () => _addAvailability(context),
              ),
              const SizedBox(height: 20),
              const Text(
                'Weekly availability',
                style: TextStyle(
                  color: dashboardInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Set the hours students can book with you.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _DaySelector(
                selectedDay: selectedDay,
                onChanged: (day) => setState(() => selectedDay = day),
              ),
              const SizedBox(height: 18),
              Text(
                selectedDay,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: dashboardGreen),
                  ),
                )
              else if (snapshot.hasError)
                const _AvailabilityEmpty(
                  message: 'Availability is unavailable right now.',
                )
              else if (items.isEmpty)
                const _AvailabilityEmpty(
                  message: 'No working hours configured yet.',
                )
              else if (selectedItems.isEmpty)
                const _AvailabilityEmpty(
                  message: 'No availability slots for this day.',
                )
              else
                ...selectedItems.map(
                  (item) => _AvailabilityRow(
                    item: item,
                    onDelete: () => _service.delete(item.id),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _addAvailability(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => _AddAvailabilityDialog(service: _service),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selectedDay, required this.onChanged});
  final String selectedDay;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _weekdayNames
          .map(
            (day) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(day.substring(0, 3)),
                selected: day == selectedDay,
                onSelected: (_) => onChanged(day),
                selectedColor: dashboardGreen,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: day == selectedDay ? Colors.white : dashboardInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                side: const BorderSide(color: Color(0xFFD6EBDD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _AvailabilityHeader extends StatelessWidget {
  const _AvailabilityHeader({required this.onBack, required this.onAdd});
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        tooltip: 'Back to calendar',
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      ),
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
                letterSpacing: .7,
              ),
            ),
            Text(
              'Working hours',
              style: TextStyle(
                color: dashboardInk,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: onAdd,
        tooltip: 'Add working hours',
        icon: const Icon(Icons.add_circle_outline, color: dashboardGreen),
      ),
    ],
  );
}

class _AddAvailabilityDialog extends StatefulWidget {
  const _AddAvailabilityDialog({required this.service});
  final AvailabilityService service;

  @override
  State<_AddAvailabilityDialog> createState() => _AddAvailabilityDialogState();
}

class _AddAvailabilityDialogState extends State<_AddAvailabilityDialog> {
  final startController = TextEditingController(text: '09:00');
  final endController = TextEditingController(text: '17:00');
  final durationController = TextEditingController(text: '45');
  String dayOfWeek = 'Monday';
  bool saving = false;

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
        dayOfWeek: dayOfWeek,
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
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: dayOfWeek,
            decoration: const InputDecoration(
              labelText: 'Day',
              prefixIcon: Icon(Icons.today_outlined),
            ),
            items: _weekdayNames
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
            onChanged: (value) => setState(() => dayOfWeek = value!),
          ),
          const SizedBox(height: 14),
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

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.item, required this.onDelete});
  final CounselorAvailabilityModel item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD6EBDD)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF7ED),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule_outlined, color: dashboardGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.dayOfWeek,
                style: const TextStyle(
                  color: dashboardInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.startTime} - ${item.endTime}  •  ${item.sessionDuration} min sessions',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Delete working hours',
          icon: const Icon(Icons.delete_outline, size: 20),
        ),
      ],
    ),
  );
}

class _AvailabilityEmpty extends StatelessWidget {
  const _AvailabilityEmpty({required this.message});
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
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

int _compareAvailability(
  CounselorAvailabilityModel a,
  CounselorAvailabilityModel b,
) {
  final dayCompare = _weekdayIndex(a.dayOfWeek).compareTo(_weekdayIndex(b.dayOfWeek));
  if (dayCompare != 0) return dayCompare;
  return a.startTime.compareTo(b.startTime);
}

int _weekdayIndex(String value) {
  final normalized = value.trim().toLowerCase();
  final index = _weekdayNames.indexWhere((day) => day.toLowerCase() == normalized);
  return index < 0 ? _weekdayNames.length : index;
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
