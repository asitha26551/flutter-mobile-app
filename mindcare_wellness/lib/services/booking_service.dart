import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../models/counselor_models.dart';

/// Top-level helper function to save an appointment to Firestore collection `appointments`.
Future<AppointmentModel> createAnonymousBooking(
  AppointmentModel appointment, {
  FirebaseFirestore? firestore,
}) {
  final service = BookingService(firestore: firestore);
  return service.createAppointment(appointment);
}

/// Service managing confidential counselor appointments and bookings.
/// Implements full CRUD (Create, Read, Update, Delete/Cancel) using the official [AppointmentModel].
class BookingService {
  BookingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _customFirestore = firestore,
        _customAuth = auth;

  static BookingService? _defaultInstance;
  static BookingService get defaultInstance =>
      _defaultInstance ??= BookingService();

  @visibleForTesting
  static void resetDefaultInstance() {
    _defaultInstance = null;
  }

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  // In-memory cache for offline, unit test, and rapid reactive UI updates
  final List<AppointmentModel> _inMemoryAppointments = [];

  final StreamController<List<AppointmentModel>> _appointmentsStreamController =
      StreamController<List<AppointmentModel>>.broadcast();

  FirebaseFirestore? get _effectiveFirestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _effectiveAuth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Current signed-in user's UID or anonymous identifier.
  String? get currentUid => _effectiveAuth?.currentUser?.uid;

  /// Reference to the `appointments` collection.
  CollectionReference<Map<String, dynamic>>? get _appointmentsCollection =>
      _effectiveFirestore?.collection('appointments');

  /// Reference to the `counselors` collection.
  CollectionReference<Map<String, dynamic>>? get _publicCounselorsCollection =>
      _effectiveFirestore?.collection('counselor_public');

  // =========================================================================
  // 1. CREATE OPERATIONS
  // =========================================================================

  /// CREATE: Books a session with validation and privacy configuration.
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    // 1. Input Validation
    if (appointment.counselorId.trim().isEmpty) {
      throw ArgumentError('Counselor ID must not be empty.');
    }
    if (appointment.sessionType.trim().isEmpty) {
      throw ArgumentError('Session format/type must be selected.');
    }

    final col = _appointmentsCollection;
    final docRef = col != null
        ? (appointment.id.trim().isNotEmpty
            ? col.doc(appointment.id.trim())
            : col.doc())
        : null;

    final id = docRef?.id ??
        (appointment.id.trim().isNotEmpty
            ? appointment.id.trim()
            : 'appointment_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}');

    final effectiveStudentId = appointment.studentId.isNotEmpty
        ? appointment.studentId
        : (currentUid ?? 'anon_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}');

    final now = DateTime.now();
    final startAt = appointment.startAt ?? now;
    final endAt = appointment.endAt ?? startAt.add(const Duration(minutes: 50));

    final finalAppointment = appointment.copyWith(
      id: id,
      studentId: effectiveStudentId,
      startAt: startAt,
      endAt: endAt,
      status: appointment.status.isNotEmpty ? appointment.status : 'confirmed',
      createdAt: appointment.createdAt ?? now,
      updatedAt: now,
    );

    // Save in memory
    final existingIndex =
        _inMemoryAppointments.indexWhere((a) => a.id == id);
    if (existingIndex >= 0) {
      _inMemoryAppointments[existingIndex] = finalAppointment;
    } else {
      _inMemoryAppointments.add(finalAppointment);
    }
    _notifyStreams();

    // Persist to Firestore
    if (docRef != null) {
      try {
        final data = finalAppointment.toFirestore();
        await docRef.set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('BookingService.createAppointment firestore error: $e');
      }
    }

    return finalAppointment;
  }

  /// Alias for [createAppointment].
  Future<AppointmentModel> createBooking(AppointmentModel appointment) =>
      createAppointment(appointment);

  /// Top-level anonymous booking wrapper.
  Future<AppointmentModel> createAnonymousBooking(AppointmentModel appointment) =>
      createAppointment(appointment);

  // =========================================================================
  // 2. READ OPERATIONS
  // =========================================================================

  /// READ: Fetches appointments for the active student/user.
  Future<List<AppointmentModel>> fetchUserAppointments({
    String? studentId,
    String? pseudonym,
    String? status,
  }) async {
    final effectiveUid = studentId ?? pseudonym ?? currentUid;
    final col = _appointmentsCollection;

    if (col != null && effectiveUid != null && effectiveUid.isNotEmpty) {
      try {
        Query<Map<String, dynamic>> query = col.where('studentId', isEqualTo: effectiveUid);
        if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
          query = query.where('status', isEqualTo: status.toLowerCase());
        }

        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          final items = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();

          for (final item in items) {
            final idx = _inMemoryAppointments.indexWhere((a) => a.id == item.id);
            if (idx >= 0) {
              _inMemoryAppointments[idx] = item;
            } else {
              _inMemoryAppointments.add(item);
            }
          }
          return _filterInMemory(
            studentId: effectiveUid,
            pseudonym: pseudonym,
            status: status,
          );
        }
      } catch (e) {
        debugPrint('BookingService.fetchUserAppointments error: $e');
      }
    }

    return _filterInMemory(
      studentId: effectiveUid,
      pseudonym: pseudonym,
      status: status,
    );
  }

  /// Alias for [fetchUserAppointments].
  Future<List<AppointmentModel>> fetchUserBookings({
    String? studentId,
    String? pseudonym,
    String? status,
  }) =>
      fetchUserAppointments(
        studentId: studentId,
        pseudonym: pseudonym,
        status: status,
      );

  /// READ: Fetches a single appointment by ID.
  Future<AppointmentModel?> getAppointmentById(String id) async {
    final cached = _inMemoryAppointments.where((a) => a.id == id);
    if (cached.isNotEmpty) return cached.first;

    final col = _appointmentsCollection;
    if (col != null) {
      try {
        final doc = await col.doc(id).get();
        if (doc.exists) {
          final item = AppointmentModel.fromFirestore(doc);
          _inMemoryAppointments.add(item);
          return item;
        }
      } catch (e) {
        debugPrint('BookingService.getAppointmentById error: $e');
      }
    }
    return null;
  }

  /// Alias for [getAppointmentById].
  Future<AppointmentModel?> getBookingById(String id) => getAppointmentById(id);

  /// Reactive Stream of appointments for a user.
  Stream<List<AppointmentModel>> userAppointmentsStream({
    String? studentId,
    String? pseudonym,
    String? status,
  }) {
    final effectiveUid = studentId ?? pseudonym ?? currentUid;
    final col = _appointmentsCollection;

    if (col != null && effectiveUid != null && effectiveUid.isNotEmpty) {
      try {
        Query<Map<String, dynamic>> query =
            col.where('studentId', isEqualTo: effectiveUid);
        if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
          query = query.where('status', isEqualTo: status.toLowerCase());
        }

        return query.snapshots().map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc))
              .toList();

          for (final item in list) {
            final idx = _inMemoryAppointments.indexWhere((a) => a.id == item.id);
            if (idx >= 0) {
              _inMemoryAppointments[idx] = item;
            } else {
              _inMemoryAppointments.add(item);
            }
          }
          return _filterInMemory(
            studentId: effectiveUid,
            pseudonym: pseudonym,
            status: status,
          );
        });
      } catch (e) {
        debugPrint('BookingService.userAppointmentsStream error: $e');
      }
    }

    return Stream<List<AppointmentModel>>.multi((controller) {
      controller.add(
        _filterInMemory(
          studentId: effectiveUid,
          pseudonym: pseudonym,
          status: status,
        ),
      );
      final sub = _appointmentsStreamController.stream.listen(
        (_) {
          controller.add(
            _filterInMemory(
              studentId: effectiveUid,
              pseudonym: pseudonym,
              status: status,
            ),
          );
        },
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  /// Alias for [userAppointmentsStream].
  Stream<List<AppointmentModel>> userBookingsStream({
    String? studentId,
    String? pseudonym,
    String? status,
  }) =>
      userAppointmentsStream(
        studentId: studentId,
        pseudonym: pseudonym,
        status: status,
      );

  List<AppointmentModel> _filterInMemory({
    String? studentId,
    String? pseudonym,
    String? status,
  }) {
    final validIds = <String>{
      if (studentId != null && studentId.isNotEmpty) studentId,
      if (pseudonym != null && pseudonym.isNotEmpty) pseudonym,
      if (currentUid != null && currentUid!.isNotEmpty) currentUid!,
    };

    return _inMemoryAppointments.where((item) {
      if (validIds.isNotEmpty) {
        if (!validIds.contains(item.studentId)) {
          return false;
        }
      }
      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
        if (item.status.toLowerCase() != status.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // =========================================================================
  // 3. UPDATE OPERATIONS (Reschedule / Edit)
  // =========================================================================

  /// UPDATE: Reschedules or modifies an appointment.
  Future<AppointmentModel> updateAppointment(AppointmentModel updated) async {
    final now = DateTime.now();
    final appointment = updated.copyWith(updatedAt: now);

    final idx = _inMemoryAppointments.indexWhere((a) => a.id == appointment.id);
    if (idx >= 0) {
      _inMemoryAppointments[idx] = appointment;
    } else {
      _inMemoryAppointments.add(appointment);
    }
    _notifyStreams();

    final col = _appointmentsCollection;
    if (col != null) {
      try {
        await col.doc(appointment.id).update(appointment.toFirestore());
      } catch (e) {
        debugPrint('BookingService.updateAppointment firestore error: $e');
      }
    }

    return appointment;
  }

  /// Alias for [updateAppointment].
  Future<AppointmentModel> updateBooking(AppointmentModel updated) =>
      updateAppointment(updated);

  /// Helper to reschedule an appointment with a new date and time slot.
  Future<AppointmentModel> rescheduleAppointment(
    String id, {
    required DateTime newDate,
    required String newTimeSlot,
    String? newNotes,
    String? newFormat,
  }) async {
    final existing = await getAppointmentById(id);
    if (existing == null) {
      throw ArgumentError('Appointment with ID $id not found.');
    }

    int hour = 9;
    int minute = 0;
    try {
      final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false)
          .firstMatch(newTimeSlot);
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
        final ampm = match.group(3)!.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
      }
    } catch (_) {}

    final startAt =
        DateTime(newDate.year, newDate.month, newDate.day, hour, minute);
    final endAt = startAt.add(const Duration(minutes: 50));

    final updated = existing.copyWith(
      startAt: startAt,
      endAt: endAt,
      studentNotes: newNotes ?? existing.studentNotes,
      sessionType: newFormat ?? existing.sessionType,
      updatedAt: DateTime.now(),
    );

    return updateAppointment(updated);
  }

  /// Alias for [rescheduleAppointment].
  Future<AppointmentModel> rescheduleBooking(
    String id, {
    required DateTime newDate,
    required String newTimeSlot,
    String? newNotes,
    String? newFormat,
  }) =>
      rescheduleAppointment(
        id,
        newDate: newDate,
        newTimeSlot: newTimeSlot,
        newNotes: newNotes,
        newFormat: newFormat,
      );

  // =========================================================================
  // 4. DELETE / CANCEL OPERATIONS
  // =========================================================================

  /// CANCEL: Soft-deletes/cancels an appointment with an optional reason.
  Future<AppointmentModel> cancelAppointment(
    String id, {
    String? cancellationReason,
    String? reason,
  }) async {
    final effectiveReason = cancellationReason ?? reason ?? 'Cancelled by student';
    final existing = await getAppointmentById(id);
    if (existing == null) {
      throw ArgumentError('Appointment with ID $id not found.');
    }

    final cancelled = existing.copyWith(
      status: 'cancelled',
      cancellationReason: effectiveReason,
      cancelledBy: currentUid ?? existing.studentId,
      updatedAt: DateTime.now(),
    );

    return updateAppointment(cancelled);
  }

  /// Alias for [cancelAppointment].
  Future<AppointmentModel> cancelBooking(
    String id, {
    String? cancellationReason,
    String? reason,
  }) =>
      cancelAppointment(
        id,
        cancellationReason: cancellationReason,
        reason: reason,
      );

  /// DELETE: Hard-deletes an appointment record permanently.
  Future<bool> deleteAppointment(String id) async {
    _inMemoryAppointments.removeWhere((a) => a.id == id);
    _notifyStreams();

    final col = _appointmentsCollection;
    if (col != null) {
      try {
        await col.doc(id).delete();
      } catch (e) {
        debugPrint('BookingService.deleteAppointment firestore error: $e');
      }
    }
    return true;
  }

  /// Alias for [deleteAppointment].
  Future<bool> deleteBooking(String id) => deleteAppointment(id);

  void _notifyStreams() {
    if (!_appointmentsStreamController.isClosed) {
      _appointmentsStreamController.add(List.unmodifiable(_inMemoryAppointments));
    }
  }

  // =========================================================================
  // 5. COUNSELOR DIRECTORY & SLOTS
  // =========================================================================

  /// Fetches counselors from Firestore or falls back to curated defaultCounselors.
  Future<List<CounselorModel>> fetchCounselors({
    bool onlyConfidentialSupported = false,
  }) async {
    try {
      final col = _publicCounselorsCollection;
      if (col != null) {
        final snapshot = await col
            .where('verificationStatus', isEqualTo: 'approved')
            .where('accountStatus', isEqualTo: 'active')
            .get();
        final list = <CounselorModel>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final accountStatus = data['accountStatus'] as String?;
          final verificationStatus = data['verificationStatus'] as String?;
          if ((accountStatus != null && accountStatus != 'active') ||
              (verificationStatus != null && verificationStatus != 'approved')) {
            continue;
          }
          final counselor = CounselorModel.fromJson({
            ...data,
            'id': doc.id,
            'name': data['fullName'] ?? data['name'] ?? 'Counselor',
            'image': data['profileImage'] ?? data['profileImageUrl'] ?? '',
            'title': data['professionalRole'] ?? data['department'] ?? '',
            'location': data['officeLocation'] ?? data['location'] ?? '',
            'tags': data['specializations'] ?? data['tags'] ?? const <String>[],
          }, id: doc.id);

          if (!onlyConfidentialSupported || counselor.isConfidentialSupported) {
            list.add(counselor);
          }
        }

        return list;
      }
    } catch (e) {
      debugPrint('BookingService.fetchCounselors error: $e');
      if (_customFirestore != null || _effectiveFirestore != null) {
        return const <CounselorModel>[];
      }
    }

    return _defaultCounselors
        .where((c) => !onlyConfidentialSupported || c.isConfidentialSupported)
        .toList();
  }

  /// Alias for [fetchCounselors].
  Future<List<CounselorModel>> getCounselors({
    bool onlyConfidentialSupported = false,
  }) =>
      fetchCounselors(onlyConfidentialSupported: onlyConfidentialSupported);

  /// Fetches a counselor by their ID.
  Future<CounselorModel?> getCounselorById(String counselorId) async {
    try {
      final col = _publicCounselorsCollection;
      if (col != null) {
        final doc = await col.doc(counselorId).get();
        if (!doc.exists || doc.data() == null) return null;
        final data = doc.data()!;
        if ((data['accountStatus'] as String? ?? '') != 'active' ||
            (data['verificationStatus'] as String? ?? '') != 'approved') {
          return null;
        }
        return CounselorModel.fromJson({
          ...data,
          'name': data['fullName'] ?? data['name'] ?? 'Counselor',
          'image': data['profileImage'] ?? data['profileImageUrl'] ?? '',
          'title': data['professionalRole'] ?? data['department'] ?? '',
          'location': data['officeLocation'] ?? data['location'] ?? '',
          'tags': data['specializations'] ?? data['tags'] ?? const <String>[],
        }, id: doc.id);
      }
    } catch (e) {
      debugPrint('BookingService.getCounselorById error: $e');
      if (_customFirestore != null || _effectiveFirestore != null) return null;
    }

    for (final c in _defaultCounselors) {
      if (c.id == counselorId) return c;
    }
    return null;
  }

  /// Fetches available booking slots for a given counselor and date.
  Future<List<String>> fetchAvailableSlots(
    String counselorId, {
    DateTime? date,
  }) async {
    final firestore = _effectiveFirestore;
    if (firestore == null || date == null) {
      final counselor = await getCounselorById(counselorId);
      return counselor?.availableSlots ?? const <String>[];
    }

    final availability = await firestore
        .collection('counselor_availability')
        .where('counselorId', isEqualTo: counselorId)
        .where('isAvailable', isEqualTo: true)
        .get();
    final weekday = _weekdayName(date.weekday).toLowerCase();
    final windows = availability.docs
        .map((doc) => doc.data())
        .where((data) =>
            (data['dayOfWeek'] as String? ?? '').toLowerCase() == weekday)
        .toList();
    if (windows.isEmpty) return const <String>[];

    // Students may only read their own appointment documents. The counselor
    // confirms pending requests, so slot discovery uses published working
    // hours and leaves appointment ownership checks to the counselor flow.
    final dayStart = DateTime(date.year, date.month, date.day);

    final slots = <String>{};
    for (final window in windows) {
      final startMinute = _minutesSinceMidnight(window['startTime'] as String? ?? '');
      final endMinute = _minutesSinceMidnight(window['endTime'] as String? ?? '');
      final duration = (window['sessionDuration'] as num?)?.toInt() ?? 45;
      if (startMinute == null || endMinute == null || duration <= 0) continue;
      for (var minute = startMinute; minute + duration <= endMinute; minute += duration) {
        final start = dayStart.add(Duration(minutes: minute));
        if (start.isBefore(DateTime.now())) continue;
        slots.add(_formatSlot(start));
      }
    }
    final result = slots.toList()
      ..sort((a, b) => _minutesSinceMidnight(a)!.compareTo(_minutesSinceMidnight(b)!));
    return result;
  }

  Future<int> fetchSlotDuration(
    String counselorId, {
    required DateTime date,
    required String slot,
  }) async {
    final firestore = _effectiveFirestore;
    if (firestore == null) return 45;
    final slotMinute = _minutesSinceMidnight(slot);
    if (slotMinute == null) return 45;
    final weekday = _weekdayName(date.weekday).toLowerCase();
    final availability = await firestore
        .collection('counselor_availability')
        .where('counselorId', isEqualTo: counselorId)
        .where('isAvailable', isEqualTo: true)
        .get();
    for (final doc in availability.docs) {
      final data = doc.data();
      if ((data['dayOfWeek'] as String? ?? '').toLowerCase() != weekday) {
        continue;
      }
      final start = _minutesSinceMidnight(data['startTime'] as String? ?? '');
      final end = _minutesSinceMidnight(data['endTime'] as String? ?? '');
      final duration = (data['sessionDuration'] as num?)?.toInt() ?? 45;
      if (start != null && end != null && duration > 0 &&
          slotMinute >= start && slotMinute + duration <= end &&
          (slotMinute - start) % duration == 0) {
        return duration;
      }
    }
    return 45;
  }

  static String _weekdayName(int weekday) => const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ][weekday - 1];

  static int? _minutesSinceMidnight(String value) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)?\s*$', caseSensitive: false)
        .firstMatch(value);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || minute > 59) return null;
    final period = match.group(3)?.toUpperCase();
    if (period != null) {
      if (hour < 1 || hour > 12) return null;
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
    }
    if (hour > 23) return null;
    return hour * 60 + minute;
  }

  static String _formatSlot(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Alias for [fetchAvailableSlots].
  Future<List<String>> getAvailableSlots(
    String counselorId, {
    DateTime? date,
  }) =>
      fetchAvailableSlots(counselorId, date: date);

  void dispose() {
    _appointmentsStreamController.close();
  }

  static const List<CounselorModel> _defaultCounselors =
      CounselorModel.defaultCounselors;
}
