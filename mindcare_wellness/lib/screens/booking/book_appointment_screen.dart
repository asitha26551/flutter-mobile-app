import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controllers/schedule_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../services/booking_service.dart';
import '../../services/appointment_service.dart';
import '../../services/privacy_service.dart';
import '../../services/student_service.dart';
import 'booking_confirmation_screen.dart';

/// Screen 4: Book Appointment Screen
/// Provides session format selection, interactive date picker / calendar,
/// categorized morning/afternoon time slot chips, reason-for-visit selection,
/// and a primary "Proceed to Review" action button navigating to [BookingConfirmationScreen].
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({
    required this.counselor,
    this.existingAppointment,
    this.existingBooking,
    this.bookingService,
    this.appointmentService,
    this.privacyService,
    super.key,
  });

  final CounselorModel counselor;
  final AppointmentModel? existingAppointment;
  final AppointmentModel? existingBooking;
  final BookingService? bookingService;
  final AppointmentService? appointmentService;
  final PrivacyService? privacyService;

  AppointmentModel? get effectiveExisting =>
      existingAppointment ?? existingBooking;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late final BookingService _bookingService;
  late final PrivacyService _privacyService;
  final StudentService _studentService = StudentService();

  bool get _isEditing => widget.effectiveExisting != null;
  bool _isSaving = false;
  bool _isAnonymousMode = true;

  // Session Format
  String _selectedFormat = 'Video Call';
  static const List<_FormatOption> _formats = [
    _FormatOption('Text Chat', Icons.chat_bubble_outline_rounded),
    _FormatOption('Audio Call', Icons.phone_outlined),
    _FormatOption('Video Call', Icons.videocam_outlined),
    _FormatOption('In-Person', Icons.person_pin_circle_outlined),
  ];

  // Calendar / Date selection
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  // Time Slots
  List<String> _availableSlots = [];
  String? _selectedSlot;
  bool _isSlotsLoading = false;

  // Reason for Visit
  String? _selectedReason;
  static const List<String> _reasons = [
    'Academic Stress',
    'Anxiety',
    'Sleep Disruption',
    'General Check-in',
    'Relationship Issues',
    'Depression / Mood',
  ];

  late CounselorModel _selectedCounselor;

  // Colors
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService.defaultInstance;
    _privacyService = widget.privacyService ?? PrivacyService.defaultInstance;
    _selectedCounselor = widget.counselor;

    final existing = widget.effectiveExisting;
    if (existing != null) {
      _selectedFormat = _formatLabel(existing.sessionType);
      if (existing.startAt != null) {
        _selectedDate = DateTime(
          existing.startAt!.year,
          existing.startAt!.month,
          existing.startAt!.day,
        );
        _currentMonth =
            DateTime(existing.startAt!.year, existing.startAt!.month, 1);
        final hour = existing.startAt!.hour == 0
            ? 12
            : (existing.startAt!.hour > 12
                ? existing.startAt!.hour - 12
                : existing.startAt!.hour);
        final minute = existing.startAt!.minute.toString().padLeft(2, '0');
        final ampm = existing.startAt!.hour >= 12 ? 'PM' : 'AM';
        _selectedSlot = '${hour.toString().padLeft(2, '0')}:$minute $ampm';
      } else {
        final now = DateTime.now();
        _selectedDate = DateTime(now.year, now.month, now.day);
        _currentMonth = DateTime(now.year, now.month, 1);
      }
      _selectedReason = existing.reason;
      _isAnonymousMode =
          existing.studentId.isNotEmpty && !existing.studentId.contains('@');
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
    }

    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isSlotsLoading = true);
    try {
      final slots = await _bookingService.fetchAvailableSlots(
        _selectedCounselor.id,
        date: _selectedDate,
      );
      if (mounted) {
        setState(() {
          final slot = _selectedSlot;
          if (_isEditing && slot != null && !slots.contains(slot)) {
            slots.insert(0, slot);
          }
          _availableSlots = slots;
          if (!_isEditing) {
            _selectedSlot = null;
          }
          _isSlotsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableSlots = <String>[];
          _isSlotsLoading = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (date.isBefore(normalizedToday)) return;

    setState(() {
      _selectedDate = date;
    });
    _loadSlots();
  }

  bool get _canProceed => _selectedSlot != null && _selectedReason != null;

  Future<void> _proceedToReview() async {
    if (!_canProceed) return;

    if (_isEditing) {
      setState(() => _isSaving = true);
      try {
        final duration = await _bookingService.fetchSlotDuration(
          _selectedCounselor.id,
          date: _selectedDate,
          slot: _selectedSlot!,
        );
        final parsedStart =
            ScheduleController.parseDateTimeSlot(_selectedDate, _selectedSlot!);
        final updated = widget.effectiveExisting!.copyWith(
          sessionType: _storedSessionType(_selectedFormat),
          startAt: parsedStart,
          endAt: parsedStart.add(Duration(minutes: duration)),
          reason: _selectedReason,
        );
        await _bookingService.updateAppointment(updated);
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment updated successfully!'),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(updated);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update appointment: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // New Booking Flow
    var pseudonym = _privacyService.createPseudonym();
    try {
      final student = await _studentService.mine();
      final configuredAlias = student?.alias?.trim() ?? '';
      final privacy = await _privacyService.getPrivacySettings();
      final savedAlias = configuredAlias.isNotEmpty
          ? configuredAlias
          : privacy.currentPseudonym.trim();
      if (savedAlias.isNotEmpty) {
        pseudonym = savedAlias;
        if (student != null && configuredAlias.isEmpty) {
          await _studentService.updateStudent(
            studentId: student.uid,
            data: {
              'alias': savedAlias,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
    } catch (_) {}
    final passcode = _privacyService.createPasscode();
    setState(() => _isSaving = true);
    late final int duration;
    try {
      duration = await _bookingService.fetchSlotDuration(
        _selectedCounselor.id,
        date: _selectedDate,
        slot: _selectedSlot!,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not verify the session duration: $error')),
        );
      }
      return;
    }
    if (mounted) setState(() => _isSaving = false);
    final parsedStart =
        ScheduleController.parseDateTimeSlot(_selectedDate, _selectedSlot!);
    final endAt = parsedStart.add(Duration(minutes: duration));

    final appointment = AppointmentModel(
      id: '',
      // Keep the authenticated UID as the database identity. The counselor
      // workflow queries appointments by this field; the alias remains a UI
      // privacy setting and is resolved by CounselorService.
      studentId: _bookingService.currentUid ?? '',
      counselorId: _selectedCounselor.id,
      startAt: parsedStart,
      endAt: endAt,
      sessionType: _storedSessionType(_selectedFormat),
      status: 'pending',
      reason: _selectedReason,
      location: _selectedCounselor.displayLocation,
      studentNotes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          appointment: appointment,
          counselor: _selectedCounselor,
          pseudonym: pseudonym,
          passcode: passcode,
          bookingService: _bookingService,
          appointmentService: widget.appointmentService,
          privacyService: _privacyService,
        ),
      ),
    );
  }

  String _storedSessionType(String label) => switch (label) {
    'Text Chat' || 'chat' => 'chat',
    'Audio Call' || 'audio' => 'audio',
    'In-Person' || 'in_person' => 'in_person',
    _ => 'video',
  };

  String _formatLabel(String value) => switch (value.toLowerCase()) {
    'chat' || 'text chat' => 'Text Chat',
    'audio' || 'audio call' => 'Audio Call',
    'in_person' || 'in-person' => 'In-Person',
    'video' || 'video call' => 'Video Call',
    _ => 'Video Call',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Appointment' : 'Book Appointment',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  // Counselor Summary Header
                  _buildCounselorHeader(),
                  if (_isEditing) ...[
                    const SizedBox(height: 18),
                    _buildPrivacyToggleCard(),
                  ],
                  const SizedBox(height: 22),

                  // 1. Session Format Selection
                  _buildSectionLabel(
                    'Session Format',
                    'Choose how you would like to connect',
                  ),
                  const SizedBox(height: 12),
                  _buildFormatSelector(),
                  const SizedBox(height: 24),

                  // 2. Interactive Date Picker / Calendar
                  _buildSectionLabel(
                    'Select Date',
                    'Choose an upcoming appointment day',
                  ),
                  const SizedBox(height: 12),
                  _buildInteractiveCalendar(),
                  const SizedBox(height: 24),

                  // 3. Time Slot Chips
                  _buildSectionLabel(
                    'Available Time Slots',
                    'Select a convenient time for your consultation',
                  ),
                  const SizedBox(height: 12),
                  _buildCategorizedTimeSlots(),
                  const SizedBox(height: 24),

                  // 4. Reason for Visit Chips
                  _buildSectionLabel(
                    'Reason for Visit',
                    'Helps the counselor prepare appropriately',
                  ),
                  const SizedBox(height: 12),
                  _buildReasonChips(),
                ],
              ),
            ),

            // 5. Proceed to Review Bottom Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
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
    );
  }

  Widget _buildCounselorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF044E38), Color(0xFF065F46), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _emeraldGreen.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.white.withValues(alpha: 0.2),
              child: _selectedCounselor.image.isNotEmpty
                  ? Image.network(
                      _selectedCounselor.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCounselor.name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedCounselor.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _selectedCounselor.displayLocation,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedCounselor.rating,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Center(
      child: Text(
        _selectedCounselor.name.isNotEmpty ? _selectedCounselor.name[0] : 'C',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  // 1. Session Format Selection Tiles
  Widget _buildFormatSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _formats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final option = _formats[index];
        final isSelected = _selectedFormat == option.label;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFormat = option.label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _mintTint : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _emeraldGreen : const Color(0xFFE2E8F0),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected ? _emeraldGreen : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? _darkEmerald
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Interactive Date Picker / Calendar
  Widget _buildInteractiveCalendar() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon, 7=Sun
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final prevMonthDisabled = _currentMonth.year == today.year &&
        _currentMonth.month <= today.month;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          // Month header & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 22,
                    color: prevMonthDisabled
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                    onPressed: prevMonthDisabled
                        ? null
                        : () {
                            setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.year,
                                _currentMonth.month - 1,
                                1,
                              );
                            });
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: 22,
                    color: const Color(0xFF334155),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month + 1,
                          1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Day Names Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final dayNumber = dayOffset + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final isPast = date.isBefore(normalizedToday);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isCurrentToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return GestureDetector(
                onTap: isPast ? null : () => _onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _emeraldGreen
                        : isCurrentToday
                            ? _mintTint
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isCurrentToday && !isSelected
                        ? Border.all(color: _mintBorder)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : isCurrentToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isPast
                                ? const Color(0xFFCBD5E1)
                                : isCurrentToday
                                    ? _darkEmerald
                                    : const Color(0xFF0F172A),
                      ),
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

  // 3. Time Slot Chips (Morning / Afternoon)
  Widget _buildCategorizedTimeSlots() {
    if (_isSlotsLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: _emeraldGreen),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No slots available on this day. Please pick another date.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final morningSlots = _availableSlots
        .where((s) => s.toUpperCase().contains('AM'))
        .toList();
    final afternoonSlots = _availableSlots
        .where((s) => s.toUpperCase().contains('PM'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morningSlots.isNotEmpty) ...[
          _buildSlotSubgroup('Morning Slots', Icons.wb_sunny_outlined, morningSlots),
          const SizedBox(height: 14),
        ],
        if (afternoonSlots.isNotEmpty) ...[
          _buildSlotSubgroup(
            'Afternoon Slots',
            Icons.wb_twilight_rounded,
            afternoonSlots,
          ),
        ],
      ],
    );
  }

  Widget _buildSlotSubgroup(
    String title,
    IconData icon,
    List<String> slots,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _emeraldGreen),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? _emeraldGreen : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? _emeraldGreen : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Reason for Visit Chips
  Widget _buildReasonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason;
        return GestureDetector(
          onTap: () => setState(() => _selectedReason = reason),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _darkEmerald : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _darkEmerald : const Color(0xFFCBD5E1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Identity & Privacy Mode Control
  Widget _buildPrivacyToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAnonymousMode ? _mintTint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAnonymousMode ? _mintBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isAnonymousMode ? Colors.white : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAnonymousMode ? Icons.shield_rounded : Icons.person_rounded,
                      color: _isAnonymousMode ? _emeraldGreen : const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isAnonymousMode ? 'Anonymous Session' : 'Standard Session',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _isAnonymousMode ? _darkEmerald : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isAnonymousMode,
                activeThumbColor: _emeraldGreen,
                activeTrackColor: _mintBorder,
                onChanged: (val) {
                  setState(() => _isAnonymousMode = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAnonymousMode
                ? 'Identity Protected: Counselor will only see your pseudonym. Real name and student ID remain zero-disclosure.'
                : 'Standard Booking: Your student ID and university name will be visible to the counseling department.',
            style: TextStyle(
              fontSize: 12,
              color: _isAnonymousMode
                  ? _darkEmerald.withValues(alpha: 0.85)
                  : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Bottom Bar with Action Button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: (_canProceed && !_isSaving) ? _proceedToReview : null,
          style: FilledButton.styleFrom(
            backgroundColor: _emeraldGreen,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            shadowColor: _emeraldGreen.withValues(alpha: 0.4),
            textStyle: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isEditing ? 'Save Changes' : 'Proceed to Review'),
                    const SizedBox(width: 8),
                    Icon(
                      _isEditing
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}

class _FormatOption {
  const _FormatOption(this.label, this.icon);
  final String label;
  final IconData icon;
}
