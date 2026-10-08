import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/schedule_controller.dart';
import '../../models/booking_model.dart';
import '../../models/counselor_model.dart';
import '../../services/booking_service.dart';
import '../../services/privacy_service.dart';
import '../counselors/counselor_directory_screen.dart';

/// Screen displaying the Student's confidential counseling appointments.
/// Implements full CRUD operations (Create, Read, Update/Reschedule, Delete/Cancel)
/// with multi-category tab filtering and anonymous passcode controls.
class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({
    this.scheduleController,
    this.bookingService,
    this.privacyService,
    this.isEmbedded = false,
    this.initialFilter = ScheduleFilter.all,
    super.key,
  });

  final ScheduleController? scheduleController;
  final BookingService? bookingService;
  final PrivacyService? privacyService;

  /// Whether this screen is rendered inside a tabbed dashboard (IndexedStack)
  /// or as a standalone route with its own Scaffold AppBar.
  final bool isEmbedded;

  final ScheduleFilter initialFilter;

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  late final ScheduleController _controller;
  bool _ownsController = false;

  // Emerald Theme constants
  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);
  static const Color _neutralDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    if (widget.scheduleController != null) {
      _controller = widget.scheduleController!;
      _ownsController = false;
    } else {
      _controller = ScheduleController(
        bookingService: widget.bookingService,
        privacyService: widget.privacyService,
      );
      _ownsController = true;
      _controller.initialize();
    }

    if (widget.initialFilter != ScheduleFilter.all) {
      _controller.setFilter(widget.initialFilter);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // =========================================================================
  // 1. CREATE OPERATION: New Booking Dialog / Modal
  // =========================================================================

  Future<void> _openNewBookingModal() async {
    // If counselors haven't loaded yet, fetch them
    if (_controller.counselors.isEmpty) {
      await _controller.refresh();
    }

    if (!mounted) return;

    final counselors = _controller.counselors;
    if (counselors.isEmpty) {
      // Navigate to directory to book
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CounselorDirectoryScreen(
            bookingService: _controller.bookingService,
            privacyService: _controller.privacyService,
          ),
        ),
      );
      return;
    }

    CounselorModel selectedCounselor = counselors.first;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = selectedCounselor.availableSlots.isNotEmpty
        ? selectedCounselor.availableSlots.first
        : '10:00 AM';
    String selectedFormat = 'Online Video';
    final notesController = TextEditingController();
    bool isAnonymous = true;
    final autoPasscode = ScheduleController.generatePasscode();

    final created = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableSlots = selectedCounselor.availableSlots.isNotEmpty
                ? selectedCounselor.availableSlots
                : const [
                    '09:30 AM',
                    '11:00 AM',
                    '02:00 PM',
                    '03:30 PM',
                    '05:00 PM',
                  ];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Anonymous Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _neutralDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _mintTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _mintBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.key_rounded,
                                size: 12,
                                color: _emeraldGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                autoPasscode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _darkEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your identity remains masked under your active pseudonym.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    // 1. Select Counselor
                    const Text(
                      'Select Counselor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CounselorModel>(
                          value: selectedCounselor,
                          isExpanded: true,
                          items: counselors.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _mintTint,
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0] : 'C',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _emeraldGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${c.name} (${c.title})',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newC) {
                            if (newC != null) {
                              setModalState(() {
                                selectedCounselor = newC;
                                if (newC.availableSlots.isNotEmpty) {
                                  selectedSlot = newC.availableSlots.first;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Delivery Mode Selection
                    const Text(
                      'Delivery Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Online Video',
                        'Confidential Chat',
                        'Audio Call',
                        'In-Person',
                      ].map((format) {
                        final isSel = selectedFormat == format;
                        return ChoiceChip(
                          label: Text(format),
                          selected: isSel,
                          selectedColor: _mintTint,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? _darkEmerald : const Color(0xFF475569),
                          ),
                          side: BorderSide(
                            color: isSel ? _emeraldGreen : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) {
                            setModalState(() => selectedFormat = format);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Date Selection
                    const Text(
                      'Session Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _emeraldGreen,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: _neutralDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: _emeraldGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(selectedDate),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _neutralDark,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Time Slot Chips
                    const Text(
                      'Select Time Slot',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSlots.map((slot) {
                        final isSel = selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSel,
                          selectedColor: _mintTint,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? _darkEmerald : const Color(0xFF475569),
                          ),
                          side: BorderSide(
                            color: isSel ? _emeraldGreen : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) {
                            setModalState(() => selectedSlot = slot);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 5. Session Notes / Focus
                    const Text(
                      'Focus / Session Notes (Confidential)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Exam anxiety, sleep disturbance, academic pressure...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _emeraldGreen, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop({
                            'counselor': selectedCounselor,
                            'date': selectedDate,
                            'slot': selectedSlot,
                            'format': selectedFormat,
                            'notes': notesController.text.trim(),
                            'passcode': autoPasscode,
                            'isAnonymous': isAnonymous,
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          'Confirm Anonymous Booking',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

    if (created != null) {
      final passcode = created['passcode'] as String;
      try {
        await _controller.createBooking(
          counselor: created['counselor'] as CounselorModel,
          date: created['date'] as DateTime,
          timeSlot: created['slot'] as String,
          sessionFormat: created['format'] as String,
          reason: created['notes'] as String,
          sessionNotes: created['notes'] as String,
          isAnonymous: created['isAnonymous'] as bool,
          customPasscode: passcode,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Session booked! Passcode assigned: $passcode',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking failed: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // =========================================================================
  // 3. UPDATE OPERATION: Reschedule / Edit Session Modal
  // =========================================================================

  Future<void> _openRescheduleModal(BookingModel booking) async {
    DateTime selectedDate = booking.date;
    String selectedSlot = booking.timeSlot;
    String selectedFormat = booking.sessionFormat;
    final notesController = TextEditingController(text: booking.reason);

    const availableSlots = [
      '09:30 AM',
      '11:00 AM',
      '02:00 PM',
      '03:30 PM',
      '05:00 PM',
    ];

    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reschedule Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _neutralDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _mintTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.counselorName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _darkEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passcode: ${booking.passcode} • Alias: ${booking.pseudonym.isNotEmpty ? booking.pseudonym : 'Confidential'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    // Date Picker
                    const Text(
                      'Select New Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate.isBefore(DateTime.now())
                              ? DateTime.now()
                              : selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _emeraldGreen,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: _neutralDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: _emeraldGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(selectedDate),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _neutralDark,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _emeraldGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slot Chips
                    const Text(
                      'Select New Time Slot',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSlots.map((slot) {
                        final isSel = selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSel,
                          selectedColor: _mintTint,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? _darkEmerald : const Color(0xFF475569),
                          ),
                          side: BorderSide(
                            color: isSel ? _emeraldGreen : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) {
                            setModalState(() => selectedSlot = slot);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Mode
                    const Text(
                      'Delivery Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        'Online Video',
                        'Confidential Chat',
                        'Audio Call',
                        'In-Person',
                      ].map((fmt) {
                        final isSel = selectedFormat == fmt;
                        return ChoiceChip(
                          label: Text(fmt),
                          selected: isSel,
                          selectedColor: _mintTint,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? _darkEmerald : const Color(0xFF475569),
                          ),
                          side: BorderSide(
                            color: isSel ? _emeraldGreen : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) {
                            setModalState(() => selectedFormat = fmt);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Notes / Focus
                    const Text(
                      'Session Notes / Focus Area',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _neutralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add or edit focus notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _emeraldGreen, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop({
                            'date': selectedDate,
                            'slot': selectedSlot,
                            'notes': notesController.text.trim(),
                            'format': selectedFormat,
                          });
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

    if (updated != null) {
      try {
        await _controller.rescheduleBooking(
          bookingId: booking.bookingId,
          newDate: updated['date'] as DateTime,
          newTimeSlot: updated['slot'] as String,
          newNotes: updated['notes'] as String,
          newFormat: updated['format'] as String,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session rescheduled successfully!'),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reschedule: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // =========================================================================
  // 4. DELETE / CANCEL OPERATION: Confirmation Dialogs
  // =========================================================================

  Future<void> _confirmCancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 8),
            Text(
              'Cancel Session?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your session with ${booking.counselorName} scheduled for ${booking.timeSlot}?\n\nYour confidential time slot will be released back to other students.',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep Session',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _controller.cancelBooking(booking.bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session cancelled successfully.'),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel session: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteRecord(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Record?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'This will permanently remove this appointment from your private history and records.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _controller.deleteBooking(booking.bookingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment record deleted permanently.'),
              backgroundColor: _emeraldGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete record: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // =========================================================================
  // 2. READ: Schedule Dashboard Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final content = RefreshIndicator(
          onRefresh: _controller.refresh,
          color: _emeraldGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              // Screen Header
              _buildHeaderSection(),
              const SizedBox(height: 16),

              // Filter Tabs / Chips
              _buildFilterChips(),
              const SizedBox(height: 18),

              // Booking List or Empty State
              _buildBookingsContent(),
            ],
          ),
        );

        if (widget.isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: _neutralDark,
            elevation: 0,
            title: const Text(
              'My Schedule',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: _emeraldGreen),
                tooltip: 'New Booking',
                onPressed: _openNewBookingModal,
              ),
            ],
          ),
          body: content,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openNewBookingModal,
            backgroundColor: _emeraldGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Book Session',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Appointments',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _neutralDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Anonymous, encrypted, and editable sessions',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          onPressed: _openNewBookingModal,
          icon: const Icon(Icons.add_rounded, size: 16, color: _emeraldGreen),
          label: const Text(
            'New',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _darkEmerald,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _mintTint,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _mintBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ScheduleFilter.values.map((filter) {
          final isSelected = _controller.currentFilter == filter;
          int count = 0;
          switch (filter) {
            case ScheduleFilter.all:
              count = _controller.allCount;
              break;
            case ScheduleFilter.upcoming:
              count = _controller.upcomingCount;
              break;
            case ScheduleFilter.pending:
              count = _controller.pendingCount;
              break;
            case ScheduleFilter.past:
              count = _controller.pastCount;
              break;
            case ScheduleFilter.cancelled:
              count = _controller.cancelledCount;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                count > 0 ? '${filter.label} ($count)' : filter.label,
              ),
              selected: isSelected,
              onSelected: (_) => _controller.setFilter(filter),
              selectedColor: _mintTint,
              checkmarkColor: _emeraldGreen,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _darkEmerald : const Color(0xFF64748B),
              ),
              side: BorderSide(
                color: isSelected ? _mintBorder : const Color(0xFFE2E8F0),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsContent() {
    final filtered = _controller.filteredBookings;

    if (filtered.isEmpty) {
      final label = _controller.currentFilter.label;
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              label == 'All' ? 'No Booked Sessions' : 'No $label Sessions',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _neutralDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label == 'Cancelled'
                  ? 'You have not cancelled any sessions.'
                  : 'You have no $label confidential sessions scheduled.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openNewBookingModal,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Book a Session'),
              style: FilledButton.styleFrom(
                backgroundColor: _emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((b) => _buildBookingCard(b)).toList(),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    final isCancelled = b.isCancelled;
    final isPending = b.isPending;
    final isCompleted = b.isCompleted;

    Color statusColor = _emeraldGreen;
    Color statusBg = _mintTint;
    String statusLabel = 'CONFIRMED';

    if (isCancelled) {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
      statusLabel = 'CANCELLED';
    } else if (isPending) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      statusLabel = 'PENDING';
    } else if (isCompleted) {
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFF0F9FF);
      statusLabel = 'COMPLETED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCancelled ? Colors.red.shade100 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Counselor & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  b.counselorName,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isCancelled
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0F172A),
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time Slot
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isCancelled
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                '${_formatDate(b.date)} • ${b.timeSlot}',
                style: TextStyle(
                  fontSize: 13,
                  color: isCancelled
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Session Delivery Format
          Row(
            children: [
              Icon(
                _getFormatIcon(b.sessionFormat),
                size: 14,
                color: isCancelled
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                b.sessionFormat,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Privacy Badges, Pseudonym & Passcode
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (b.isAnonymousMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _mintTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _mintBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: _emeraldGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.pseudonym.isNotEmpty
                            ? 'Alias: ${b.pseudonym}'
                            : '100% Anonymous',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _darkEmerald,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Standard Session',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),

              // Unique Anonymous Passcode Card with 1-tap Copy
              if (b.passcode.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: b.passcode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Passcode ${b.passcode} copied to clipboard!'),
                        backgroundColor: _emeraldGreen,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Passcode: ${b.passcode}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (b.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Focus: ${b.reason}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // CRUD Actions: Reschedule (Update), Cancel, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCancelled && !isCompleted) ...[
                OutlinedButton.icon(
                  onPressed: () => _openRescheduleModal(b),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _emeraldGreen,
                    side: const BorderSide(color: _mintBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmCancelBooking(b),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 15,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: () => _confirmDeleteRecord(b),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: Color(0xFF94A3B8),
                  ),
                  label: const Text(
                    'Delete Record',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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

  IconData _getFormatIcon(String format) {
    final lower = format.toLowerCase();
    if (lower.contains('chat') || lower.contains('text')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (lower.contains('audio') || lower.contains('call') || lower.contains('phone')) {
      return Icons.phone_in_talk_rounded;
    }
    if (lower.contains('person') || lower.contains('clinic')) {
      return Icons.location_on_outlined;
    }
    return Icons.videocam_outlined;
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
