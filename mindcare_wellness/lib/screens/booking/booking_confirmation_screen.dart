import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/schedule_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/counselor_models.dart';
import '../../services/booking_service.dart';
import '../../services/privacy_service.dart';
import 'my_schedule_screen.dart';

/// Screen 5: Booking Confirmation & Review Screen
/// Displays verified anonymous status, appointment parameters, active pseudonym badge,
/// passcode with "Copy Code" button, confidentiality rules checklist,
/// and full-width Emerald Green "Confirm Booking" action saving to Firestore.
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({
    this.appointment,
    this.booking,
    this.counselor,
    this.bookingService,
    this.privacyService,
    super.key,
  }) : assert(appointment != null || booking != null, 'Either appointment or booking must be provided');

  final AppointmentModel? appointment;
  final AppointmentModel? booking;
  final CounselorModel? counselor;
  final BookingService? bookingService;
  final PrivacyService? privacyService;

  AppointmentModel get effectiveAppointment => (appointment ?? booking)!;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late final BookingService _bookingService;
  late final PrivacyService _privacyService;

  bool _isConfirming = false;
  bool _isConfirmed = false;
  AppointmentModel? _confirmedAppointment;
  CounselorModel? _resolvedCounselor;

  // Checklist states
  bool _rule1Checked = true;
  bool _rule2Checked = true;
  bool _rule3Checked = true;

  static const Color _emeraldGreen = Color(0xFF059669);
  static const Color _darkEmerald = Color(0xFF064E3B);
  static const Color _mintTint = Color(0xFFECFDF5);
  static const Color _mintBorder = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService.defaultInstance;
    _privacyService = widget.privacyService ?? PrivacyService.defaultInstance;
    _resolvedCounselor = widget.counselor;
    _resolveCounselorIfNeeded();
  }

  Future<void> _resolveCounselorIfNeeded() async {
    if (_resolvedCounselor == null && widget.effectiveAppointment.counselorId.isNotEmpty) {
      final c = await _bookingService.getCounselorById(widget.effectiveAppointment.counselorId);
      if (c != null && mounted) {
        setState(() {
          _resolvedCounselor = c;
        });
      }
    }
  }

  String get _effectivePseudonym {
    final sid = widget.effectiveAppointment.studentId.trim();
    if (sid.isNotEmpty && !sid.contains('@')) {
      return sid;
    }
    return 'SilentPanda42';
  }

  String get _effectivePasscode {
    final notes = widget.effectiveAppointment.studentNotes ?? '';
    final match = RegExp(r'Passcode:\s*([A-Za-z0-9\-]+)', caseSensitive: false)
        .firstMatch(notes);
    if (match != null) {
      return match.group(1)!;
    }
    return 'STU-8821';
  }

  String _formatDateTimeSlot(DateTime? dt) {
    if (dt == null) return '09:00 AM';
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    try {
      final existingNotes = widget.effectiveAppointment.studentNotes ?? '';
      final updatedNotes = existingNotes.contains('Passcode:')
          ? existingNotes
          : (existingNotes.isNotEmpty
              ? '$existingNotes | Passcode: $_effectivePasscode'
              : 'Passcode: $_effectivePasscode');

      final toSave = widget.effectiveAppointment.copyWith(
        studentId: _effectivePseudonym,
        studentNotes: updatedNotes,
        status: 'confirmed',
      );

      final saved = await _bookingService.createAppointment(toSave);

      // Persist active pseudonym & passcode to privacy settings
      try {
        final currentSettings = await _privacyService.getPrivacySettings();
        await _privacyService.savePrivacySettings(
          currentSettings.copyWith(
            currentPseudonym: _effectivePseudonym,
            passcode: _effectivePasscode,
          ),
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isConfirming = false;
          _isConfirmed = true;
          _confirmedAppointment = saved;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anonymous booking confirmed successfully!'),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm booking: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyPasscode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passcode copied to clipboard!'),
        backgroundColor: _emeraldGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfirmed && _confirmedAppointment != null) {
      return _buildSuccessView(_confirmedAppointment!);
    }

    final counselor = _resolvedCounselor ?? widget.counselor;
    final appointment = widget.effectiveAppointment;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(
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
                  // 1. "Anonymous Booking Verified" top status card
                  _buildStatusCard(),
                  const SizedBox(height: 18),

                  // 2. Appointment details summary
                  _buildAppointmentSummaryCard(appointment, counselor),
                  const SizedBox(height: 18),

                  // 3. Active Pseudonym display badge & 4. Anonymous Passcode card
                  _buildIdentityAndPasscodeCard(),
                  const SizedBox(height: 18),

                  // 5. Confidentiality rules checklist
                  _buildConfidentialityRulesCard(),
                ],
              ),
            ),

            // 6. Full-width Emerald Green "Confirm Booking" button
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  /// 1. "Anonymous Booking Verified" top status card
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mintTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _emeraldGreen.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _emeraldGreen.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _emeraldGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anonymous Booking Verified',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkEmerald,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Zero-data disclosure active. Your real identity is isolated from counselor scheduling.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Appointment details summary
  Widget _buildAppointmentSummaryCard(
    AppointmentModel appointment,
    CounselorModel? counselor,
  ) {
    final counselorName = counselor?.name.isNotEmpty == true
        ? counselor!.name
        : 'Senior Counselor';

    final counselorTitle = counselor?.title.isNotEmpty == true
        ? counselor!.title
        : 'University Counselor';

    final counselorLocation = counselor?.displayLocation ??
        (appointment.location ?? 'Campus Wellness Center');

    final dt = appointment.startAt ?? DateTime.now();
    final formattedDate =
        '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
    final formattedSlot = _formatDateTimeSlot(appointment.startAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPOINTMENT DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // Counselor Row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 52,
                  height: 52,
                  color: _mintTint,
                  child: counselor?.image.isNotEmpty == true
                      ? Image.network(
                          counselor!.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _avatarFallback(counselorName),
                        )
                      : _avatarFallback(counselorName),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counselorName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      counselorTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: _emeraldGreen,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            counselorLocation,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
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
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Session Type / Format
          _summaryRow(
            icon: _getFormatIcon(appointment.sessionType),
            label: 'Session Format',
            value: appointment.sessionType,
          ),
          const SizedBox(height: 10),

          // Date & Time
          _summaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date & Time',
            value: '$formattedDate at $formattedSlot',
          ),
          const SizedBox(height: 10),

          // Reason for visit
          _summaryRow(
            icon: Icons.psychology_outlined,
            label: 'Reason for Visit',
            value: appointment.reason ?? 'General Consultation',
          ),
        ],
      ),
    );
  }

  /// 3. Active Pseudonym display badge & 4. Anonymous Passcode card
  Widget _buildIdentityAndPasscodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIDENTIAL IDENTITY & ACCESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // Active Pseudonym Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Pseudonym',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Counselor will greet you as this alias',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _mintTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _mintBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: _emeraldGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _effectivePseudonym,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _darkEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Anonymous Passcode Card with "Copy Code" button
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANONYMOUS PASSCODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _effectivePasscode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyPasscode(_effectivePasscode),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copy Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _emeraldGreen,
                    side: const BorderSide(color: _emeraldGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Confidentiality rules checklist
  Widget _buildConfidentialityRulesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.rule_folder_outlined, size: 18, color: _emeraldGreen),
              SizedBox(width: 8),
              Text(
                'CONFIDENTIALITY RULES CHECKLIST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _checklistTile(
            title: '100% Zero-Data Disclosure',
            subtitle: 'Your student ID and legal name are never sent to the counselor.',
            isChecked: _rule1Checked,
            onChanged: (v) => setState(() => _rule1Checked = v ?? true),
          ),
          _checklistTile(
            title: 'Separated Clinical Records',
            subtitle: 'Consultation notes are isolated and unlinked from academic files.',
            isChecked: _rule2Checked,
            onChanged: (v) => setState(() => _rule2Checked = v ?? true),
          ),
          _checklistTile(
            title: 'Encrypted Ephemeral Access',
            subtitle: 'This session can only be unlocked with your secure passcode.',
            isChecked: _rule3Checked,
            onChanged: (v) => setState(() => _rule3Checked = v ?? true),
          ),
        ],
      ),
    );
  }

  Widget _checklistTile({
    required String title,
    required String subtitle,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isChecked,
            activeColor: _emeraldGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: onChanged,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Full-width Emerald Green button: "Confirm Booking"
  Widget _buildBottomActionBar() {
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
          onPressed: _isConfirming ? null : _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: _emeraldGreen,
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
          child: _isConfirming
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Confirm Booking'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppointmentModel appointment) {
    final counselor = _resolvedCounselor ?? widget.counselor;
    final counselorName = counselor?.name.isNotEmpty == true
        ? counselor!.name
        : 'Senior Counselor';

    final formattedSlot = _formatDateTimeSlot(appointment.startAt);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: _mintTint,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: _emeraldGreen,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your session has been securely booked under your confidential pseudonym.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _successRow('Counselor', counselorName),
                    const SizedBox(height: 10),
                    _successRow('Format', appointment.sessionType),
                    const SizedBox(height: 10),
                    _successRow('Time', formattedSlot),
                    const SizedBox(height: 10),
                    _successRow('Pseudonym', _effectivePseudonym),
                    const SizedBox(height: 10),
                    _successRow('Passcode', _effectivePasscode),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _mintTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _mintBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: _emeraldGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep your passcode handy to enter your session securely.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MyScheduleScreen(
                          bookingService: _bookingService,
                          privacyService: _privacyService,
                          initialFilter: ScheduleFilter.upcoming,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('View in My Schedule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _mintTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _emeraldGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _successRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'MC';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: _emeraldGreen,
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'text chat':
        return Icons.chat_bubble_outline_rounded;
      case 'audio call':
        return Icons.phone_outlined;
      case 'in-person':
        return Icons.person_pin_circle_outlined;
      case 'video call':
      default:
        return Icons.videocam_outlined;
    }
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}
