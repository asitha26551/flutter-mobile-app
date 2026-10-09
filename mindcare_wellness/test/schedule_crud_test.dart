import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/controllers/schedule_controller.dart';
import 'package:mindcare_wellness/models/appointment_model.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/screens/booking/my_schedule_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

void main() {
  group('ScheduleController CRUD Operations', () {
    late BookingService bookingService;
    late PrivacyService privacyService;
    late ScheduleController controller;

    setUp(() async {
      bookingService = BookingService();
      privacyService = PrivacyService();
      controller = ScheduleController(
        bookingService: bookingService,
        privacyService: privacyService,
      );
      await controller.initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    test('1. CREATE: Auto-assigns Anonymous Passcode STU-XXXX and creates booking', () async {
      const counselor = CounselorModel(
        id: 'c_test_1',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Wellness Center Rm 101',
        rating: '4.9',
      );

      final date = DateTime(2026, 11, 15);
      final appointment = await controller.createBooking(
        counselor: counselor,
        date: date,
        timeSlot: '09:30 AM',
        sessionFormat: 'Online Video',
        sessionNotes: 'Need strategies for exam stress',
        isAnonymous: true,
      );

      // Verify notes contains passcode format STU-XXXX
      expect(appointment.studentNotes, contains('Passcode: STU-'));
      expect(appointment.counselorId, equals('c_test_1'));
      expect(appointment.sessionType, equals('Online Video'));
      expect(appointment.status.toLowerCase(), equals('confirmed'));
      expect(appointment.isUpcoming, isTrue);

      // Verify in controller state
      expect(controller.allAppointments.any((b) => b.id == appointment.id), isTrue);
      expect(controller.upcomingCount, equals(1));
    });

    test('2. READ: Filters by Upcoming, Pending, Past, Cancelled, and All', () async {
      const counselor = CounselorModel(
        id: 'c_test_read',
        name: 'Dr. Marcus Vance',
        title: 'Therapist',
        location: 'Wellness Center',
        rating: '4.8',
      );

      // Add 4 different status bookings
      await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 11, 20),
        timeSlot: '10:00 AM',
        sessionFormat: 'Online Video',
        status: 'confirmed',
      );

      await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 11, 22),
        timeSlot: '11:30 AM',
        sessionFormat: 'In-Person',
        status: 'pending',
      );

      await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 10, 1),
        timeSlot: '02:00 PM',
        sessionFormat: 'Confidential Chat',
        status: 'completed',
      );

      final toCancel = await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 10, 5),
        timeSlot: '03:30 PM',
        sessionFormat: 'Audio Call',
        status: 'confirmed',
      );
      await controller.cancelAppointment(toCancel.id);

      // Test filters
      controller.setFilter(ScheduleFilter.upcoming);
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.isUpcoming, isTrue);

      controller.setFilter(ScheduleFilter.pending);
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.isPending, isTrue);

      controller.setFilter(ScheduleFilter.past);
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.isCompleted, isTrue);

      controller.setFilter(ScheduleFilter.cancelled);
      expect(controller.filteredAppointments.length, equals(1));
      expect(controller.filteredAppointments.first.isCancelled, isTrue);

      controller.setFilter(ScheduleFilter.all);
      expect(controller.filteredAppointments.length, equals(4));
    });

    test('3. UPDATE: Reschedules Date, Time Slot, and Session Notes', () async {
      const counselor = CounselorModel(
        id: 'c_test_update',
        name: 'Dr. Sarah Perera',
        title: 'Therapist',
        location: 'Wellness Center',
        rating: '4.9',
      );

      final original = await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 11, 10),
        timeSlot: '09:30 AM',
        sessionFormat: 'Online Video',
        sessionNotes: 'Original notes',
      );

      final newDate = DateTime(2026, 11, 12);
      final updated = await controller.rescheduleBooking(
        original.id,
        newDate: newDate,
        newTimeSlot: '03:30 PM',
        newNotes: 'Updated exam prep notes',
        newFormat: 'Confidential Chat',
      );

      expect(updated.startAt?.year, equals(newDate.year));
      expect(updated.startAt?.month, equals(newDate.month));
      expect(updated.startAt?.day, equals(newDate.day));
      expect(updated.reason, equals('Updated exam prep notes'));
      expect(updated.sessionType, equals('Confidential Chat'));

      // Check backend persistence
      final fetched = await bookingService.getAppointmentById(original.id);
      expect(fetched!.reason, equals('Updated exam prep notes'));
    });

    test('4. DELETE: Soft-delete (Cancel) and Hard-delete (Delete Record)', () async {
      const counselor = CounselorModel(
        id: 'c_test_delete',
        name: 'Dr. Marcus Vance',
        title: 'Therapist',
        location: 'Wellness Center',
        rating: '4.8',
      );

      final booking = await controller.createBooking(
        counselor: counselor,
        date: DateTime(2026, 11, 14),
        timeSlot: '02:00 PM',
        sessionFormat: 'In-Person',
      );

      // Soft delete: Cancel
      final cancelled = await controller.cancelAppointment(
        booking.id,
        cancelReason: 'Personal emergency',
      );
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.cancellationReason, contains('Personal emergency'));

      // Hard delete: Permanent deletion
      await controller.deleteAppointment(booking.id);
      expect(controller.allAppointments.any((b) => b.id == booking.id), isFalse);

      final inBackend = await bookingService.getAppointmentById(booking.id);
      expect(inBackend, isNull);
    });
  });

  group('MyScheduleScreen Widget Tests (Full CRUD Flow)', () {
    testWidgets('Renders tabbed filters, cards with badges and passcode, and handles Reschedule and Cancel',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bookingService = BookingService();
      final privacyService = PrivacyService();

      // Seed an active booking
      await bookingService.createAppointment(
        AppointmentModel(
          id: 'bk_screen_test',
          counselorId: 'counselor_sarah',
          studentId: 'SilentPanda42',
          sessionType: 'Online Video',
          startAt: DateTime(2026, 11, 10, 11, 0),
          endAt: DateTime(2026, 11, 10, 11, 50),
          studentNotes: 'Academic Stress Management | Passcode: STU-9902',
          reason: 'Academic Stress Management',
          status: 'confirmed',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MyScheduleScreen(
            bookingService: bookingService,
            privacyService: privacyService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Header and Filter Chips rendered
      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.text('My Appointments'), findsOneWidget);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Upcoming (1)'), findsOneWidget);

      // 2. Verify Card Details & Passcode
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Online Video'), findsOneWidget);
      expect(find.text('Alias: SilentPanda42'), findsOneWidget);
      expect(find.text('Passcode: STU-9902'), findsOneWidget);
      expect(find.text('Focus: Academic Stress Management'), findsOneWidget);

      // 3. Test Reschedule (UPDATE)
      expect(find.text('Reschedule'), findsOneWidget);
      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();

      expect(find.text('Reschedule Session'), findsOneWidget);
      expect(find.text('Select New Time Slot'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Tap 02:00 PM slot
      await tester.tap(find.text('02:00 PM'));
      await tester.pumpAndSettle();

      // Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify SnackBar and updated slot in card
      expect(find.text('Session rescheduled successfully!'), findsOneWidget);
      expect(find.textContaining('02:00 PM'), findsOneWidget);

      // 4. Test Cancel (DELETE soft-delete)
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Session?'), findsOneWidget);
      expect(find.text('Confirm Cancel'), findsOneWidget);

      await tester.tap(find.text('Confirm Cancel'));
      await tester.pumpAndSettle();

      // Card now reflects CANCELLED status
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('Delete Record'), findsOneWidget);

      // 5. Test Delete Record (DELETE hard-delete)
      await tester.tap(find.text('Delete Record'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Record?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Record deleted, empty state shown
      expect(find.text('No Booked Sessions'), findsOneWidget);
    });

    testWidgets('CREATE Booking via New Session Modal in MyScheduleScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bookingService = BookingService();
      final privacyService = PrivacyService();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: MyScheduleScreen(
            bookingService: bookingService,
            privacyService: privacyService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "+ New" button
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();

      expect(find.text('New Anonymous Booking'), findsOneWidget);
      expect(find.text('Confirm Anonymous Booking'), findsOneWidget);
      expect(find.textContaining('STU-'), findsOneWidget);

      // Tap Confirm Anonymous Booking
      await tester.tap(find.text('Confirm Anonymous Booking'));
      await tester.pumpAndSettle();

      // Booking created and displayed
      expect(find.textContaining('Session booked! Passcode assigned:'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
    });
  });
}
