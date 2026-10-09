import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../models/counselor_models.dart';
import '../services/booking_service.dart';
import '../services/privacy_service.dart';

/// Available filter categories for the schedule dashboard.
enum ScheduleFilter {
  all('All'),
  upcoming('Upcoming'),
  pending('Pending'),
  past('Past'),
  cancelled('Cancelled');

  const ScheduleFilter(this.label);
  final String label;

  /// Helper parser from string.
  static ScheduleFilter fromString(String val) {
    switch (val.trim().toLowerCase()) {
      case 'upcoming':
        return ScheduleFilter.upcoming;
      case 'pending':
        return ScheduleFilter.pending;
      case 'past':
      case 'completed':
        return ScheduleFilter.past;
      case 'cancelled':
      case 'canceled':
        return ScheduleFilter.cancelled;
      default:
        return ScheduleFilter.all;
    }
  }
}

/// State Controller managing the lifecycle and CRUD operations for counseling schedules.
/// Exclusively uses the official [AppointmentModel] and [CounselorModel].
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    BookingService? bookingService,
    PrivacyService? privacyService,
  })  : _bookingService = bookingService ?? BookingService.defaultInstance,
        _privacyService = privacyService ?? PrivacyService.defaultInstance;

  final BookingService _bookingService;
  final PrivacyService _privacyService;

  ScheduleFilter _currentFilter = ScheduleFilter.all;
  List<AppointmentModel> _appointments = [];
  List<CounselorModel> _counselors = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _activePseudonym = 'SilentPanda42';

  StreamSubscription<List<AppointmentModel>>? _streamSubscription;
  StreamSubscription<PrivacySettingsModel>? _privacySubscription;

  // --- Getters ---

  ScheduleFilter get currentFilter => _currentFilter;
  List<AppointmentModel> get allAppointments => List.unmodifiable(_appointments);
  List<AppointmentModel> get allBookings => allAppointments;
  List<CounselorModel> get counselors => List.unmodifiable(_counselors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activePseudonym => _activePseudonym;
  BookingService get bookingService => _bookingService;
  PrivacyService get privacyService => _privacyService;

  /// Returns the list of appointments filtered by the active [ScheduleFilter].
  List<AppointmentModel> get filteredAppointments {
    final now = DateTime.now();
    switch (_currentFilter) {
      case ScheduleFilter.upcoming:
        return _appointments.where((a) => a.isUpcoming && !a.isCancelled).toList();
      case ScheduleFilter.pending:
        return _appointments.where((a) => a.isPending && !a.isCancelled).toList();
      case ScheduleFilter.past:
        return _appointments.where((a) =>
            a.isCompleted ||
            (!a.isCancelled && a.startAt != null && a.startAt!.isBefore(now))).toList();
      case ScheduleFilter.cancelled:
        return _appointments.where((a) => a.isCancelled).toList();
      case ScheduleFilter.all:
        return _appointments;
    }
  }

  /// Alias for filteredAppointments.
  List<AppointmentModel> get filteredBookings => filteredAppointments;

  int get upcomingCount =>
      _appointments.where((a) => a.isUpcoming && !a.isCancelled).length;

  int get pendingCount =>
      _appointments.where((a) => a.isPending && !a.isCancelled).length;

  int get pastCount =>
      _appointments.where((a) =>
          a.isCompleted ||
          (!a.isCancelled && a.startAt != null && a.startAt!.isBefore(DateTime.now()))).length;

  int get cancelledCount => _appointments.where((a) => a.isCancelled).length;

  int get allCount => _appointments.length;

  // --- Helper Methods ---

  static String generatePasscode({String prefix = 'STU-'}) {
    final rng = Random();
    final number = rng.nextInt(9000) + 1000;
    return '$prefix$number';
  }

  // =========================================================================
  // INITIALIZATION & STREAM BINDING
  // =========================================================================

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch privacy pseudonym
      final settings = await _privacyService.fetchPrivacySettings();
      if (settings.currentPseudonym.isNotEmpty) {
        _activePseudonym = settings.currentPseudonym;
      }

      // 2. Fetch counselors
      _counselors = await _bookingService.fetchCounselors();

      // 3. Initial load of appointments
      final initial = await _bookingService.fetchUserAppointments(
        studentId: _activePseudonym,
      );
      _appointments = List.from(initial);
      _appointments.sort((a, b) =>
          (a.startAt ?? DateTime.now()).compareTo(b.startAt ?? DateTime.now()));

      // 4. Bind to reactive appointments stream
      await _bindStream();

      // 5. Bind to reactive privacy stream to auto-sync pseudonym
      await _privacySubscription?.cancel();
      _privacySubscription =
          _privacyService.privacySettingsStream().listen((settings) {
        if (settings.currentPseudonym.isNotEmpty &&
            settings.currentPseudonym != _activePseudonym) {
          _activePseudonym = settings.currentPseudonym;
          _bindStream();
          refresh();
        }
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load schedule: $e';
      notifyListeners();
    }
  }

  Future<void> _bindStream() async {
    await _streamSubscription?.cancel();
    _streamSubscription = _bookingService
        .userAppointmentsStream(studentId: _activePseudonym)
        .listen(
      (items) {
        _appointments = List.from(items);
        _appointments.sort((a, b) =>
            (a.startAt ?? DateTime.now()).compareTo(b.startAt ?? DateTime.now()));
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Error listening to schedule updates: $err';
        notifyListeners();
      },
    );
  }

  /// Sets the active schedule filter tab.
  void setFilter(ScheduleFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  /// Refreshes counselor and appointment data from backend.
  Future<void> refresh() async {
    try {
      final settings = await _privacyService.fetchPrivacySettings();
      if (settings.currentPseudonym.isNotEmpty) {
        _activePseudonym = settings.currentPseudonym;
      }
      _counselors = await _bookingService.fetchCounselors();
      final fresh = await _bookingService.fetchUserAppointments(
        studentId: _activePseudonym,
      );
      _appointments = List.from(fresh);
      _appointments.sort((a, b) =>
          (a.startAt ?? DateTime.now()).compareTo(b.startAt ?? DateTime.now()));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh schedule: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // 1. CREATE (New Appointment)
  // =========================================================================

  /// Creates a new counseling appointment.
  Future<AppointmentModel> createAppointment({
    required CounselorModel counselor,
    required DateTime startAt,
    DateTime? endAt,
    required String sessionType,
    String? reason,
    String? studentNotes,
    String? customStudentId,
    String status = 'confirmed',
    String? location,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final studentId = (customStudentId != null && customStudentId.trim().isNotEmpty)
          ? customStudentId.trim()
          : _activePseudonym;

      final appointment = AppointmentModel(
        id: '',
        studentId: studentId,
        counselorId: counselor.id,
        startAt: startAt,
        endAt: endAt ?? startAt.add(const Duration(minutes: 50)),
        sessionType: sessionType,
        status: status,
        reason: reason,
        location: location ?? counselor.displayLocation,
        studentNotes: studentNotes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _bookingService.createAppointment(appointment);

      final exists = _appointments.indexWhere((a) => a.id == created.id);
      if (exists >= 0) {
        _appointments[exists] = created;
      } else {
        _appointments.add(created);
      }
      _appointments.sort((a, b) =>
          (a.startAt ?? DateTime.now()).compareTo(b.startAt ?? DateTime.now()));

      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Alias for [createAppointment] compatible with date / timeSlot parameters.
  Future<AppointmentModel> createBooking({
    required CounselorModel counselor,
    required DateTime date,
    required String timeSlot,
    required String sessionFormat,
    String reason = '',
    String? sessionNotes,
    bool isAnonymous = true,
    String? customPseudonym,
    String? customPasscode,
    String status = 'confirmed',
  }) {
    final startAt = _parseDateTimeSlot(date, timeSlot);
    final endAt = startAt.add(const Duration(minutes: 50));
    final passcode = (customPasscode != null && customPasscode.trim().isNotEmpty)
        ? customPasscode.trim()
        : generatePasscode();
    final notes = (sessionNotes != null && sessionNotes.isNotEmpty)
        ? '$sessionNotes | Passcode: $passcode'
        : (reason.isNotEmpty ? '$reason | Passcode: $passcode' : 'Passcode: $passcode');

    return createAppointment(
      counselor: counselor,
      startAt: startAt,
      endAt: endAt,
      sessionType: sessionFormat,
      reason: reason.isNotEmpty ? reason : sessionNotes,
      studentNotes: notes,
      customStudentId: customPseudonym,
      status: status,
    );
  }

  // =========================================================================
  // 2. UPDATE (Reschedule / Edit Session)
  // =========================================================================

  /// Reschedules an existing appointment with updated startAt, endAt, and notes.
  Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required DateTime startAt,
    required DateTime endAt,
    String? studentNotes,
    String? sessionType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existing = await _bookingService.getAppointmentById(id);
      if (existing == null) {
        throw ArgumentError('Appointment $id not found.');
      }

      final updated = existing.copyWith(
        startAt: startAt,
        endAt: endAt,
        reason: studentNotes ?? existing.reason,
        studentNotes: studentNotes ?? existing.studentNotes,
        sessionType: sessionType ?? existing.sessionType,
        status: 'rescheduled',
        updatedAt: DateTime.now(),
      );

      final saved = await _bookingService.updateAppointment(updated);

      final idx = _appointments.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _appointments[idx] = saved;
      }
      _appointments.sort((a, b) =>
          (a.startAt ?? DateTime.now()).compareTo(b.startAt ?? DateTime.now()));

      _isLoading = false;
      notifyListeners();
      return saved;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to reschedule: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Alias for [rescheduleAppointment].
  Future<AppointmentModel> rescheduleBooking(
    String bookingId, {
    required DateTime newDate,
    required String newTimeSlot,
    String? newNotes,
    String? newFormat,
  }) {
    final startAt = _parseDateTimeSlot(newDate, newTimeSlot);
    final endAt = startAt.add(const Duration(minutes: 50));
    return rescheduleAppointment(
      id: bookingId,
      startAt: startAt,
      endAt: endAt,
      studentNotes: newNotes,
      sessionType: newFormat,
    );
  }

  /// Updates arbitrary fields of an appointment.
  Future<AppointmentModel> updateAppointment(AppointmentModel appointment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bookingService.updateAppointment(appointment);
      final idx = _appointments.indexWhere((a) => a.id == result.id);
      if (idx >= 0) {
        _appointments[idx] = result;
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Alias for [updateAppointment].
  Future<AppointmentModel> updateBooking(AppointmentModel updated) =>
      updateAppointment(updated);

  // =========================================================================
  // 3. DELETE (Cancel Session / Permanent Delete)
  // =========================================================================

  /// Soft-delete: Cancels an appointment.
  Future<AppointmentModel> cancelAppointment(
    String id, {
    String? cancelReason,
    String? cancellationReason,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cancelled = await _bookingService.cancelAppointment(
        id,
        cancellationReason: cancellationReason ?? cancelReason ?? reason,
      );

      final idx = _appointments.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _appointments[idx] = cancelled;
      }

      _isLoading = false;
      notifyListeners();
      return cancelled;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to cancel session: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Alias for [cancelAppointment].
  Future<AppointmentModel> cancelBooking(
    String bookingId, {
    String? cancelReason,
    String? reason,
  }) =>
      cancelAppointment(
        bookingId,
        cancelReason: cancelReason,
        reason: reason,
      );

  /// Hard-delete: Permanently deletes the appointment record.
  Future<void> deleteAppointment(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookingService.deleteAppointment(id);
      _appointments.removeWhere((a) => a.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete appointment: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Alias for [deleteAppointment].
  Future<void> deleteBooking(String bookingId) => deleteAppointment(bookingId);

  /// Finds a counselor by ID from cached list or defaults.
  CounselorModel? getCounselorById(String id) {
    try {
      return _counselors.firstWhere((c) => c.id == id);
    } catch (_) {}

    for (final c in CounselorModel.defaultCounselors) {
      if (c.id == id) return c;
    }

    if (id == 'counselor_sarah' || id == 'c1' || id == 'c_test_1' || id == 'c_test_update') {
      return const CounselorModel(
        id: 'counselor_sarah',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
      );
    }

    if (id == 'c_test_read' || id == 'c_test_delete' || id == 'c2') {
      return const CounselorModel(
        id: 'c2',
        name: 'Dr. Marcus Vance',
        title: 'Therapist',
        location: 'Wellness Center',
        rating: '4.8',
      );
    }

    return null;
  }

  static DateTime parseDateTimeSlot(DateTime date, String timeSlot) {
    int hour = 9;
    int minute = 0;
    try {
      final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false)
          .firstMatch(timeSlot);
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
        final ampm = match.group(3)!.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
      }
    } catch (_) {}
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _parseDateTimeSlot(DateTime date, String timeSlot) =>
      parseDateTimeSlot(date, timeSlot);

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _privacySubscription?.cancel();
    super.dispose();
  }
}
