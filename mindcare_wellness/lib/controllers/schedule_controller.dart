import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/counselor_model.dart';
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
/// Supports reactive stream binding, anonymous passcodes, and role/privacy filtering.
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    BookingService? bookingService,
    PrivacyService? privacyService,
  })  : _bookingService = bookingService ?? BookingService(),
        _privacyService = privacyService ?? PrivacyService();

  final BookingService _bookingService;
  final PrivacyService _privacyService;

  ScheduleFilter _currentFilter = ScheduleFilter.all;
  List<BookingModel> _bookings = [];
  List<CounselorModel> _counselors = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _activePseudonym = 'SilentPanda42';

  StreamSubscription<List<BookingModel>>? _streamSubscription;

  // --- Getters ---

  ScheduleFilter get currentFilter => _currentFilter;
  List<BookingModel> get allBookings => List.unmodifiable(_bookings);
  List<CounselorModel> get counselors => List.unmodifiable(_counselors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activePseudonym => _activePseudonym;
  BookingService get bookingService => _bookingService;
  PrivacyService get privacyService => _privacyService;

  /// Returns the list of bookings filtered by the active [ScheduleFilter].
  List<BookingModel> get filteredBookings {
    switch (_currentFilter) {
      case ScheduleFilter.upcoming:
        return _bookings.where((b) => b.isUpcoming && !b.isCancelled).toList();
      case ScheduleFilter.pending:
        return _bookings.where((b) => b.isPending && !b.isCancelled).toList();
      case ScheduleFilter.past:
        return _bookings.where((b) => b.isPast && !b.isCancelled).toList();
      case ScheduleFilter.cancelled:
        return _bookings.where((b) => b.isCancelled).toList();
      case ScheduleFilter.all:
        return _bookings;
    }
  }

  int get upcomingCount =>
      _bookings.where((b) => b.isUpcoming && !b.isCancelled).length;

  int get pendingCount =>
      _bookings.where((b) => b.isPending && !b.isCancelled).length;

  int get pastCount =>
      _bookings.where((b) => b.isPast && !b.isCancelled).length;

  int get cancelledCount => _bookings.where((b) => b.isCancelled).length;

  int get allCount => _bookings.length;

  /// Initialize controller, load initial data, and bind reactive stream.
  Future<void> initialize({String? initialPseudonym}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch privacy settings
      final settings = await _privacyService.getPrivacySettings();
      if (initialPseudonym != null && initialPseudonym.isNotEmpty) {
        _activePseudonym = initialPseudonym;
      } else if (settings.currentPseudonym.isNotEmpty) {
        _activePseudonym = settings.currentPseudonym;
      }

      // 2. Fetch available counselors
      _counselors = await _bookingService.fetchCounselors();

      // 3. Bind to reactive bookings stream
      await _bindStream();

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
        .userBookingsStream(pseudonym: _activePseudonym)
        .listen(
      (items) {
        _bookings = List.from(items);
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

  /// Refreshes counselor and booking data from backend.
  Future<void> refresh() async {
    try {
      _counselors = await _bookingService.fetchCounselors();
      final fresh = await _bookingService.fetchUserBookings(
        pseudonym: _activePseudonym,
      );
      _bookings = List.from(fresh);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh schedule: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // 1. CREATE (New Booking)
  // =========================================================================

  /// Automatically generates an anonymous student passcode (e.g., `STU-9902`).
  static String generatePasscode() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'STU-$number';
  }

  /// Creates a new counseling appointment.
  /// Automatically generates an Anonymous Passcode (`STU-XXXX`) if not provided.
  Future<BookingModel> createBooking({
    required CounselorModel counselor,
    required DateTime date,
    required String timeSlot,
    required String sessionFormat,
    String reason = '',
    String? sessionNotes,
    bool isAnonymous = true,
    String? customPseudonym,
    String? customPasscode,
    String status = 'Confirmed',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final passcode = (customPasscode != null && customPasscode.trim().isNotEmpty)
          ? customPasscode.trim()
          : generatePasscode();

      final pseudonym = (customPseudonym != null && customPseudonym.trim().isNotEmpty)
          ? customPseudonym.trim()
          : _activePseudonym;

      final booking = BookingModel(
        bookingId: '',
        counselorId: counselor.id,
        counselorName: counselor.name,
        sessionFormat: sessionFormat,
        date: date,
        timeSlot: timeSlot,
        pseudonym: pseudonym,
        passcode: passcode,
        reason: (sessionNotes != null && sessionNotes.isNotEmpty)
            ? sessionNotes
            : reason,
        isAnonymousMode: isAnonymous,
        status: status,
      );

      final created = await _bookingService.createBooking(booking);

      // Immediately update local cache for snappy UI
      final exists = _bookings.indexWhere((b) => b.bookingId == created.bookingId);
      if (exists >= 0) {
        _bookings[exists] = created;
      } else {
        _bookings.add(created);
      }
      _bookings.sort((a, b) => a.date.compareTo(b.date));

      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // 2. UPDATE (Reschedule / Edit Session)
  // =========================================================================

  /// Reschedules an existing session with updated Date, Time Slot, and optional Session Notes/Format.
  Future<BookingModel> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTimeSlot,
    String? newNotes,
    String? newFormat,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _bookingService.rescheduleBooking(
        bookingId,
        newDate: newDate,
        newTimeSlot: newTimeSlot,
        newFormat: newFormat,
        newNotes: newNotes,
      );

      final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (idx >= 0) {
        _bookings[idx] = updated;
      }
      _bookings.sort((a, b) => a.date.compareTo(b.date));

      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to reschedule: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Updates arbitrary fields of a booking model.
  Future<BookingModel> updateBooking(BookingModel updatedBooking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bookingService.updateBooking(updatedBooking);
      final idx = _bookings.indexWhere((b) => b.bookingId == result.bookingId);
      if (idx >= 0) {
        _bookings[idx] = result;
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // 3. DELETE (Cancel Session / Permanent Delete)
  // =========================================================================

  /// Soft-delete: Cancels an appointment and marks its status as "Cancelled".
  Future<BookingModel> cancelBooking(
    String bookingId, {
    String? cancelReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cancelled = await _bookingService.cancelBooking(
        bookingId,
        cancelReason: cancelReason,
      );

      final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (idx >= 0) {
        _bookings[idx] = cancelled;
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

  /// Hard-delete: Permanently deletes the booking record from the database.
  Future<void> deleteBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookingService.deleteBooking(bookingId);
      _bookings.removeWhere((b) => b.bookingId == bookingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Finds a counselor by ID from cached list.
  CounselorModel? getCounselorById(String id) {
    try {
      return _counselors.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
