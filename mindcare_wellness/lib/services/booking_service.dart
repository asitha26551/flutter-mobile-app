import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/counselor_model.dart';

/// Top-level helper function to save an anonymous booking to Firestore collection `anonymous_bookings`.
Future<BookingModel> createAnonymousBooking(
  BookingModel booking, {
  FirebaseFirestore? firestore,
}) {
  final service = BookingService(firestore: firestore);
  return service.createAnonymousBooking(booking);
}

/// Service managing confidential counselor appointments and anonymous bookings.
/// Implements full CRUD (Create, Read, Update, Delete/Cancel) with fallback
/// in-memory state and role-based / anonymity filters.
class BookingService {
  BookingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _customFirestore = firestore,
        _customAuth = auth;

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  // In-memory cache for offline, unit test, and rapid reactive UI updates
  final List<BookingModel> _inMemoryBookings = [];

  final StreamController<List<BookingModel>> _bookingsStreamController =
      StreamController<List<BookingModel>>.broadcast();

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

  /// Current signed-in user's UID or anonymous UID.
  String? get currentUid => _effectiveAuth?.currentUser?.uid;

  /// Reference to the `anonymous_bookings` collection.
  CollectionReference<Map<String, dynamic>>? get _anonymousBookings =>
      _effectiveFirestore?.collection('anonymous_bookings');

  /// Reference to the `counselors` collection.
  CollectionReference<Map<String, dynamic>>? get _counselors =>
      _effectiveFirestore?.collection('counselors');

  // =========================================================================
  // 1. CREATE OPERATIONS
  // =========================================================================

  /// CREATE: Books a session with validation and privacy configuration.
  Future<BookingModel> createBooking(BookingModel booking) async {
    // 1. Input Validation
    if (booking.counselorId.trim().isEmpty) {
      throw ArgumentError('Counselor ID must not be empty.');
    }
    if (booking.timeSlot.trim().isEmpty) {
      throw ArgumentError('Time slot must be selected.');
    }
    if (booking.sessionFormat.trim().isEmpty) {
      throw ArgumentError('Session format must be selected.');
    }

    final col = _anonymousBookings;
    final docRef = col != null
        ? (booking.bookingId.trim().isNotEmpty
            ? col.doc(booking.bookingId.trim())
            : col.doc())
        : null;

    final bookingId = docRef?.id ??
        (booking.bookingId.trim().isNotEmpty
            ? booking.bookingId.trim()
            : 'booking_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}');

    final effectiveStudentId = booking.studentId.isNotEmpty
        ? booking.studentId
        : (currentUid ?? 'anon_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}');

    final now = DateTime.now();

    final finalBooking = booking.copyWith(
      bookingId: bookingId,
      studentId: effectiveStudentId,
      status: booking.status.isNotEmpty ? booking.status : 'Confirmed',
      createdAt: booking.createdAt ?? now,
      updatedAt: now,
    );

    // Save locally
    final existingIndex =
        _inMemoryBookings.indexWhere((b) => b.bookingId == bookingId);
    if (existingIndex >= 0) {
      _inMemoryBookings[existingIndex] = finalBooking;
    } else {
      _inMemoryBookings.add(finalBooking);
    }
    _notifyStreams();

    // Persist to Firestore
    if (docRef != null) {
      try {
        final data = <String, dynamic>{
          ...finalBooking.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('BookingService.createBooking Firestore error: $e');
      }
    }

    return finalBooking;
  }

  /// Saves an anonymous booking to Firestore collection `anonymous_bookings`.
  Future<BookingModel> createAnonymousBooking(BookingModel booking) {
    return createBooking(booking.copyWith(isAnonymousMode: true));
  }

  // =========================================================================
  // 2. READ OPERATIONS
  // =========================================================================

  /// READ: Fetches user bookings filtered by student ID or pseudonym (RBAC & Anonymity).
  Future<List<BookingModel>> fetchUserBookings({
    String? studentId,
    String? pseudonym,
    String? status,
  }) async {
    final results = <BookingModel>[];
    final col = _anonymousBookings;

    if (col != null) {
      try {
        Query<Map<String, dynamic>> query = col;

        if (pseudonym != null && pseudonym.isNotEmpty) {
          query = query.where('pseudonym', isEqualTo: pseudonym);
        } else if (studentId != null && studentId.isNotEmpty) {
          query = query.where('studentId', isEqualTo: studentId);
        }

        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
          results.add(BookingModel.fromJson(doc.data(), bookingId: doc.id));
        }
      } catch (e) {
        debugPrint('BookingService.fetchUserBookings query error: $e');
      }
    }

    // Merge in-memory bookings that match filter
    for (final memoryBooking in _inMemoryBookings) {
      if (!results.any((b) => b.bookingId == memoryBooking.bookingId)) {
        bool matches = true;
        if (pseudonym != null && pseudonym.isNotEmpty) {
          matches = memoryBooking.pseudonym == pseudonym;
        } else if (studentId != null && studentId.isNotEmpty) {
          matches = memoryBooking.studentId == studentId;
        }
        if (matches) {
          results.add(memoryBooking);
        }
      }
    }

    // Apply status filter if provided
    var filtered = results;
    if (status != null && status.isNotEmpty) {
      filtered = filtered
          .where((b) => b.status.toLowerCase() == status.toLowerCase())
          .toList();
    }

    // Sort by date ascending (soonest first)
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  /// READ: Fetches a single booking record by ID with optional passcode verification.
  Future<BookingModel?> getBookingById(
    String bookingId, {
    String? passcode,
  }) async {
    // 1. Check in-memory first
    final memoryMatch = _inMemoryBookings.where((b) => b.bookingId == bookingId);
    if (memoryMatch.isNotEmpty) {
      final booking = memoryMatch.first;
      if (passcode != null && passcode.isNotEmpty && booking.passcode != passcode) {
        throw StateError('Invalid passcode for this confidential booking.');
      }
      return booking;
    }

    // 2. Check Firestore
    try {
      final col = _anonymousBookings;
      if (col == null) return null;
      final doc = await col.doc(bookingId).get();
      if (!doc.exists || doc.data() == null) return null;

      final booking = BookingModel.fromJson(doc.data(), bookingId: doc.id);
      if (passcode != null && passcode.isNotEmpty && booking.passcode != passcode) {
        throw StateError('Invalid passcode for this confidential booking.');
      }
      return booking;
    } catch (e) {
      debugPrint('BookingService.getBookingById error: $e');
      rethrow;
    }
  }

  /// Alias for [getBookingById] for backward compatibility.
  Future<BookingModel?> getAnonymousBooking(
    String bookingId, {
    String? passcode,
  }) =>
      getBookingById(bookingId, passcode: passcode);

  /// Reactive stream of bookings for a student or pseudonym.
  Stream<List<BookingModel>> userBookingsStream({
    String? studentId,
    String? pseudonym,
  }) async* {
    // 1. Immediately yield the current in-memory matches
    yield _filterList(_inMemoryBookings, studentId, pseudonym);

    final col = _anonymousBookings;
    if (col != null) {
      Query<Map<String, dynamic>> query = col;
      if (pseudonym != null && pseudonym.isNotEmpty) {
        query = query.where('pseudonym', isEqualTo: pseudonym);
      } else if (studentId != null && studentId.isNotEmpty) {
        query = query.where('studentId', isEqualTo: studentId);
      }

      yield* query.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((doc) => BookingModel.fromJson(doc.data(), bookingId: doc.id))
            .toList();

        // Include any in-memory items not yet indexed remotely
        for (final memoryBooking in _inMemoryBookings) {
          if (!list.any((b) => b.bookingId == memoryBooking.bookingId)) {
            if (_matchesFilter(memoryBooking, studentId, pseudonym)) {
              list.add(memoryBooking);
            }
          }
        }

        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      });
      return;
    }

    // 2. Stream subsequent updates
    yield* _bookingsStreamController.stream.map((list) {
      return _filterList(list, studentId, pseudonym);
    });
  }

  /// Reactive stream for anonymous bookings (backward compatible).
  Stream<List<BookingModel>> anonymousBookingsStream({String? pseudonym}) =>
      userBookingsStream(pseudonym: pseudonym);

  bool _matchesFilter(BookingModel b, String? studentId, String? pseudonym) {
    if (pseudonym != null && pseudonym.isNotEmpty) {
      return b.pseudonym == pseudonym;
    }
    if (studentId != null && studentId.isNotEmpty) {
      return b.studentId == studentId;
    }
    return true;
  }

  List<BookingModel> _filterList(
    List<BookingModel> source,
    String? studentId,
    String? pseudonym,
  ) {
    final list = source.where((b) => _matchesFilter(b, studentId, pseudonym)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // =========================================================================
  // 3. UPDATE OPERATIONS
  // =========================================================================

  /// UPDATE: Modifies an existing booking with new details (date, slot, format, reason, etc.).
  Future<BookingModel> updateBooking(BookingModel updatedBooking) async {
    if (updatedBooking.bookingId.trim().isEmpty) {
      throw ArgumentError('Booking ID is required for update.');
    }

    final now = DateTime.now();
    final finalUpdated = updatedBooking.copyWith(updatedAt: now);

    // Update in-memory
    final idx = _inMemoryBookings
        .indexWhere((b) => b.bookingId == updatedBooking.bookingId);
    if (idx >= 0) {
      _inMemoryBookings[idx] = finalUpdated;
    } else {
      _inMemoryBookings.add(finalUpdated);
    }
    _notifyStreams();

    // Update in Firestore
    final col = _anonymousBookings;
    if (col != null) {
      try {
        final docRef = col.doc(updatedBooking.bookingId);
        await docRef.set({
          ...finalUpdated.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('BookingService.updateBooking Firestore error: $e');
      }
    }

    return finalUpdated;
  }

  /// UPDATE: Reschedules an existing session to a new date and time slot.
  Future<BookingModel> rescheduleBooking(
    String bookingId, {
    required DateTime newDate,
    required String newTimeSlot,
    String? newFormat,
    String? newNotes,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw StateError('Booking with ID $bookingId was not found.');
    }

    final updated = existing.copyWith(
      date: newDate,
      timeSlot: newTimeSlot,
      sessionFormat: newFormat ?? existing.sessionFormat,
      reason: newNotes ?? existing.reason,
      status: 'Confirmed',
    );
    return updateBooking(updated);
  }

  /// UPDATE: Toggles anonymous mode or changes pseudonym/passcode on an existing booking.
  Future<BookingModel> updateBookingPrivacy(
    String bookingId, {
    required bool isAnonymousMode,
    String? pseudonym,
    String? passcode,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw StateError('Booking with ID $bookingId was not found.');
    }

    final updated = existing.copyWith(
      isAnonymousMode: isAnonymousMode,
      pseudonym: pseudonym ?? existing.pseudonym,
      passcode: passcode ?? existing.passcode,
    );
    return updateBooking(updated);
  }

  // =========================================================================
  // 4. DELETE / CANCEL OPERATIONS
  // =========================================================================

  /// CANCEL: Sets status to "Cancelled" while retaining record for audit log.
  Future<BookingModel> cancelBooking(
    String bookingId, {
    String? cancelReason,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw StateError('Booking with ID $bookingId was not found.');
    }

    final updated = existing.copyWith(
      status: 'Cancelled',
      reason: cancelReason != null && cancelReason.isNotEmpty
          ? '${existing.reason} (Cancelled: $cancelReason)'
          : existing.reason,
    );
    return updateBooking(updated);
  }

  /// DELETE: Permanently deletes a booking from storage.
  Future<void> deleteBooking(String bookingId) async {
    _inMemoryBookings.removeWhere((b) => b.bookingId == bookingId);
    _notifyStreams();

    final col = _anonymousBookings;
    if (col != null) {
      try {
        await col.doc(bookingId).delete();
      } catch (e) {
        debugPrint('BookingService.deleteBooking error: $e');
      }
    }
  }

  void _notifyStreams() {
    _bookingsStreamController.add(List.unmodifiable(_inMemoryBookings));
  }

  // =========================================================================
  // COUNSELOR BROWSING & AVAILABILITY
  // =========================================================================

  /// Fetches the list of counselors from Firestore.
  /// Falls back to curated default counselor data if Firestore collection is empty.
  Future<List<CounselorModel>> fetchCounselors({
    bool onlyConfidentialSupported = false,
  }) async {
    try {
      final col = _counselors;
      if (col != null) {
        final snapshot = await col.get();
        if (snapshot.docs.isNotEmpty) {
          final list = <CounselorModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            String name =
                data['name'] as String? ?? data['fullName'] as String? ?? '';
            String image = data['image'] as String? ??
                data['profileImageUrl'] as String? ??
                '';

            if (name.isEmpty) {
              try {
                final userDoc = await _effectiveFirestore
                    ?.collection('users')
                    .doc(doc.id)
                    .get();
                final userData = userDoc?.data();
                if (userData != null) {
                  name = userData['fullName'] as String? ?? 'Counselor';
                  image = userData['profileImageUrl'] as String? ?? image;
                }
              } catch (_) {}
            }

            final counselor = CounselorModel.fromJson({
              ...data,
              'id': doc.id,
              if (name.isNotEmpty) 'name': name,
              if (image.isNotEmpty) 'image': image,
            }, id: doc.id);

            if (!onlyConfidentialSupported || counselor.isConfidentialSupported) {
              list.add(counselor);
            }
          }

          if (list.isNotEmpty) return list;
        }
      }
    } catch (e) {
      debugPrint('BookingService.fetchCounselors error: $e');
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
      final col = _counselors;
      if (col != null) {
        final doc = await col.doc(counselorId).get();
        if (doc.exists && doc.data() != null) {
          return CounselorModel.fromJson(doc.data(), id: doc.id);
        }
      }
    } catch (e) {
      debugPrint('BookingService.getCounselorById error: $e');
    }

    for (final c in _defaultCounselors) {
      if (c.id == counselorId) return c;
    }
    if (counselorId == 'counselor_sarah') {
      return const CounselorModel(
        id: 'counselor_sarah',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
        isConfidentialSupported: true,
        availableSlots: ['09:30 AM', '11:00 AM', '02:00 PM', '03:30 PM'],
      );
    }
    return null;
  }

  /// Fetches available booking slots for a given counselor and date.
  /// Automatically filters out already booked slots from `anonymous_bookings`.
  Future<List<String>> fetchAvailableSlots(
    String counselorId, {
    DateTime? date,
  }) async {
    List<String> rawSlots = const <String>[];

    final counselor = await getCounselorById(counselorId);
    if (counselor != null && counselor.availableSlots.isNotEmpty) {
      rawSlots = counselor.availableSlots;
    }

    if (rawSlots.isEmpty) {
      rawSlots = const [
        '09:00 AM - 10:00 AM',
        '10:30 AM - 11:30 AM',
        '01:00 PM - 02:00 PM',
        '02:30 PM - 03:30 PM',
        '04:00 PM - 05:00 PM',
      ];
    }

    final col = _anonymousBookings;
    if (date != null && col != null) {
      try {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final query = await col
            .where('counselorId', isEqualTo: counselorId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        final bookedSlots = query.docs
            .map((doc) => doc.data()['timeSlot'] as String? ?? '')
            .toSet();

        return rawSlots.where((slot) => !bookedSlots.contains(slot)).toList();
      } catch (e) {
        debugPrint('BookingService.fetchAvailableSlots filter error: $e');
      }
    }

    return rawSlots;
  }

  /// Alias for [fetchAvailableSlots].
  Future<List<String>> getAvailableSlots(
    String counselorId, {
    DateTime? date,
  }) =>
      fetchAvailableSlots(counselorId, date: date);

  void dispose() {
    _bookingsStreamController.close();
  }

  static const List<CounselorModel> _defaultCounselors =
      CounselorModel.defaultCounselors;
}
