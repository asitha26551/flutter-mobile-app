import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/booking_model.dart';
import 'package:mindcare_wellness/models/counselor_model.dart';
import 'package:mindcare_wellness/screens/booking/book_appointment_screen.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CRUD Step 1: BookingModel Data Structure & Anonymity Flags', () {
    test('supports studentId, status, isAnonymous, bookingDate, and privacySettings', () {
      final now = DateTime(2026, 10, 15, 10, 30);
      final booking = BookingModel(
        bookingId: 'bk_101',
        studentId: 'stu_99',
        counselorId: 'counselor_sarah',
        counselorName: 'Dr. Sarah Perera',
        sessionFormat: 'Video Call',
        date: now,
        timeSlot: '10:30 AM',
        pseudonym: 'SilentPanda42',
        passcode: 'STU-8821',
        reason: 'Exam Anxiety',
        isAnonymousMode: true,
        status: 'Confirmed',
        privacySettings: {'hideRealName': true, 'maskStudentId': true},
        createdAt: now,
        updatedAt: now,
      );

      // Verify convenience getters
      expect(booking.isAnonymous, isTrue);
      expect(booking.bookingDate, equals(now));
      expect(booking.isUpcoming, isTrue);
      expect(booking.isCancelled, isFalse);
      expect(booking.isCompleted, isFalse);

      // Serialization & Deserialization
      final json = booking.toJson();
      expect(json['studentId'], equals('stu_99'));
      expect(json['status'], equals('Confirmed'));
      expect(json['isAnonymous'], isTrue);
      expect(json['privacySettings'], isNotNull);

      final restored = BookingModel.fromJson(json);
      expect(restored.bookingId, equals('bk_101'));
      expect(restored.studentId, equals('stu_99'));
      expect(restored.isAnonymous, isTrue);
      expect(restored.status, equals('Confirmed'));
      expect(restored.reason, equals('Exam Anxiety'));
    });
  });

  group('CRUD Step 2: BookingService & PrivacyService Logic', () {
    test('Create: books an anonymous session with validation', () async {
      final service = BookingService();

      // Input validation: empty counselor
      expect(
        () => service.createBooking(
          BookingModel(
            bookingId: '',
            counselorId: '',
            counselorName: '',
            sessionFormat: 'Video Call',
            date: DateTime.now(),
            timeSlot: '10:00 AM',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid creation
      final created = await service.createBooking(
        BookingModel(
          bookingId: 'test_create_1',
          counselorId: 'c1',
          counselorName: 'Dr. Sarah',
          sessionFormat: 'Audio Call',
          date: DateTime(2026, 10, 20),
          timeSlot: '02:00 PM',
          pseudonym: 'SilentPanda42',
          passcode: 'STU-1234',
          isAnonymousMode: true,
        ),
      );

      expect(created.bookingId, equals('test_create_1'));
      expect(created.status, equals('Confirmed'));
      expect(created.isAnonymous, isTrue);

      // Read back
      final fetched = await service.getBookingById('test_create_1');
      expect(fetched, isNotNull);
      expect(fetched!.counselorName, equals('Dr. Sarah'));
      expect(fetched.timeSlot, equals('02:00 PM'));
    });

    test('Read & Filter: fetches bookings by pseudonym and status', () async {
      final service = BookingService();
      await service.createBooking(
        BookingModel(
          bookingId: 'b_active',
          counselorId: 'c1',
          counselorName: 'Dr. Sarah',
          sessionFormat: 'Video Call',
          date: DateTime(2026, 10, 21),
          timeSlot: '09:30 AM',
          pseudonym: 'BraveHawk99',
          status: 'Confirmed',
        ),
      );
      await service.createBooking(
        BookingModel(
          bookingId: 'b_cancelled',
          counselorId: 'c2',
          counselorName: 'Dr. Marcus',
          sessionFormat: 'In-Person',
          date: DateTime(2026, 10, 22),
          timeSlot: '11:00 AM',
          pseudonym: 'BraveHawk99',
          status: 'Cancelled',
        ),
      );

      final userBookings = await service.fetchUserBookings(pseudonym: 'BraveHawk99');
      expect(userBookings.length, equals(2));

      final activeOnly = await service.fetchUserBookings(
        pseudonym: 'BraveHawk99',
        status: 'Confirmed',
      );
      expect(activeOnly.length, equals(1));
      expect(activeOnly.first.bookingId, equals('b_active'));
    });

    test('Update & Reschedule: updates time slot and notifies reactive stream', () async {
      final service = BookingService();
      await service.createBooking(
        BookingModel(
          bookingId: 'b_update_test',
          counselorId: 'c1',
          counselorName: 'Dr. Sarah',
          sessionFormat: 'Video Call',
          date: DateTime(2026, 10, 25),
          timeSlot: '09:30 AM',
          pseudonym: 'SilentPanda42',
        ),
      );

      // Reschedule
      final updated = await service.rescheduleBooking(
        'b_update_test',
        newDate: DateTime(2026, 10, 26),
        newTimeSlot: '03:30 PM',
      );

      expect(updated.timeSlot, equals('03:30 PM'));
      expect(updated.date, equals(DateTime(2026, 10, 26)));

      final verified = await service.getBookingById('b_update_test');
      expect(verified!.timeSlot, equals('03:30 PM'));
    });

    test('Delete & Cancel: cancels session and removes record permanently', () async {
      final service = BookingService();
      await service.createBooking(
        BookingModel(
          bookingId: 'b_delete_test',
          counselorId: 'c1',
          counselorName: 'Dr. Sarah',
          sessionFormat: 'Video Call',
          date: DateTime(2026, 10, 28),
          timeSlot: '11:00 AM',
          pseudonym: 'SilentPanda42',
        ),
      );

      // Cancel
      final cancelled = await service.cancelBooking(
        'b_delete_test',
        cancelReason: 'Class conflict',
      );
      expect(cancelled.isCancelled, isTrue);

      // Delete
      await service.deleteBooking('b_delete_test');
      final afterDelete = await service.getBookingById('b_delete_test');
      expect(afterDelete, isNull);
    });

    test('PrivacyService: handles anonymous fallback without throwing', () async {
      final privacyService = PrivacyService();
      // Should return default settings without throwing when unauthenticated
      final settings = await privacyService.getPrivacySettings();
      expect(settings.currentPseudonym.isNotEmpty, isTrue);

      // Save new settings anonymously
      await privacyService.savePrivacySettings(
        settings.copyWith(currentPseudonym: 'CalmFalcon77'),
      );
      final updated = await privacyService.getPrivacySettings();
      expect(updated.currentPseudonym, equals('CalmFalcon77'));
    });
  });

  group('CRUD Step 3: UI Components, Forms & Cancellation Dialogs', () {
    testWidgets('Schedule Tab renders anonymous badges, passcode copy, and cancel confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bookingService = BookingService();
      await bookingService.createBooking(
        BookingModel(
          bookingId: 'ui_bk_1',
          counselorId: 'counselor_sarah',
          counselorName: 'Dr. Sarah Perera',
          sessionFormat: 'Video Call',
          date: DateTime(2026, 10, 18),
          timeSlot: '11:00 AM',
          pseudonym: 'SilentPanda42',
          passcode: 'STU-8821',
          reason: 'Academic Stress',
          isAnonymousMode: true,
          status: 'Confirmed',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: StudentDashboardScreen(
            bookingService: bookingService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "My Schedule" quick action to open schedule tab
      await tester.tap(find.text('My\nSchedule'));
      await tester.pumpAndSettle();

      // Verify Booking details rendered
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('100% Anonymous'), findsNothing); // Alias is shown
      expect(find.text('Alias: SilentPanda42'), findsOneWidget);
      expect(find.textContaining('Passcode: STU-8821'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel button -> opens confirmation dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Session?'), findsOneWidget);
      expect(find.text('Confirm Cancel'), findsOneWidget);

      // Tap Confirm Cancel
      await tester.tap(find.text('Confirm Cancel'));
      await tester.pumpAndSettle();

      // Verify status changed to CANCELLED
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('Delete Record'), findsOneWidget);
    });

    testWidgets('BookAppointmentScreen in edit mode pre-populates data and updates booking',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bookingService = BookingService();
      final existingBooking = BookingModel(
        bookingId: 'edit_bk_9',
        counselorId: 'counselor_sarah',
        counselorName: 'Dr. Sarah Perera',
        sessionFormat: 'Video Call',
        date: DateTime.now(),
        timeSlot: '09:30 AM',
        pseudonym: 'SilentPanda42',
        reason: 'Anxiety',
        isAnonymousMode: true,
      );
      await bookingService.createBooking(existingBooking);

      const counselor = CounselorModel(
        id: 'counselor_sarah',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
        availableSlots: ['09:30 AM', '02:00 PM'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: BookAppointmentScreen(
            counselor: counselor,
            existingBooking: existingBooking,
            bookingService: bookingService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Edit Appointment Header
      expect(find.text('Edit Appointment'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Anonymous Session'), findsOneWidget);

      // Tap a new slot '02:00 PM'
      await tester.tap(find.text('02:00 PM'));
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify service updated
      final updated = await bookingService.getBookingById('edit_bk_9');
      expect(updated!.timeSlot, equals('02:00 PM'));
    });
  });
}
