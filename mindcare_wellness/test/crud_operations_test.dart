import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/appointment_model.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/screens/booking/book_appointment_screen.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CRUD Step 1: AppointmentModel Data Structure & Fields', () {
    test('supports studentId, status, startAt, endAt, reason, and studentNotes', () {
      final now = DateTime(2026, 10, 15, 10, 30);
      final appointment = AppointmentModel(
        id: 'bk_101',
        studentId: 'stu_99',
        counselorId: 'counselor_sarah',
        sessionType: 'Video Call',
        startAt: now,
        endAt: now.add(const Duration(minutes: 50)),
        status: 'confirmed',
        reason: 'Exam Anxiety',
        studentNotes: 'Passcode: STU-8821',
        createdAt: now,
        updatedAt: now,
      );

      // Verify convenience getters
      expect(appointment.studentId, equals('stu_99'));
      expect(appointment.startAt, equals(now));
      expect(appointment.isUpcoming, isTrue);
      expect(appointment.isCancelled, isFalse);
      expect(appointment.isCompleted, isFalse);

      // Serialization & Deserialization
      final map = appointment.toFirestore();
      expect(map['studentId'], equals('stu_99'));
      expect(map['status'], equals('confirmed'));
      expect(map['sessionType'], equals('Video Call'));
      expect(map['studentNotes'], equals('Passcode: STU-8821'));

      final restored = AppointmentModel.fromMap('bk_101', {
        ...map,
        'startAt': now,
        'endAt': now.add(const Duration(minutes: 50)),
      });
      expect(restored.id, equals('bk_101'));
      expect(restored.studentId, equals('stu_99'));
      expect(restored.status, equals('confirmed'));
      expect(restored.reason, equals('Exam Anxiety'));
    });
  });

  group('CRUD Step 2: BookingService & PrivacyService Logic', () {
    test('Create: books an anonymous session with validation', () async {
      final service = BookingService();

      // Input validation: empty counselor
      expect(
        () => service.createAppointment(
          AppointmentModel(
            id: '',
            studentId: '',
            counselorId: '',
            sessionType: 'Video Call',
            startAt: DateTime.now(),
            endAt: DateTime.now().add(const Duration(minutes: 50)),
            status: 'confirmed',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid creation
      final created = await service.createAppointment(
        AppointmentModel(
          id: 'test_create_1',
          studentId: 'SilentPanda42',
          counselorId: 'c1',
          sessionType: 'Audio Call',
          startAt: DateTime(2026, 10, 20, 14, 0),
          endAt: DateTime(2026, 10, 20, 14, 50),
          status: 'confirmed',
          studentNotes: 'Passcode: STU-1234',
        ),
      );

      expect(created.id, equals('test_create_1'));
      expect(created.status, equals('confirmed'));
      expect(created.isUpcoming, isTrue);

      // Read back
      final fetched = await service.getAppointmentById('test_create_1');
      expect(fetched, isNotNull);
      expect(fetched!.counselorId, equals('c1'));
      expect(fetched.sessionType, equals('Audio Call'));
    });

    test('Read & Filter: fetches appointments by studentId and status', () async {
      final service = BookingService();
      await service.createAppointment(
        AppointmentModel(
          id: 'b_active',
          studentId: 'BraveHawk99',
          counselorId: 'c1',
          sessionType: 'Video Call',
          startAt: DateTime(2026, 10, 21, 9, 30),
          endAt: DateTime(2026, 10, 21, 10, 20),
          status: 'confirmed',
        ),
      );
      await service.createAppointment(
        AppointmentModel(
          id: 'b_cancelled',
          studentId: 'BraveHawk99',
          counselorId: 'c2',
          sessionType: 'In-Person',
          startAt: DateTime(2026, 10, 22, 11, 0),
          endAt: DateTime(2026, 10, 22, 11, 50),
          status: 'cancelled',
        ),
      );

      final userBookings = await service.fetchUserAppointments(studentId: 'BraveHawk99');
      expect(userBookings.length, equals(2));

      final activeOnly = await service.fetchUserAppointments(
        studentId: 'BraveHawk99',
        status: 'confirmed',
      );
      expect(activeOnly.length, equals(1));
      expect(activeOnly.first.id, equals('b_active'));
    });

    test('Update & Reschedule: updates time slot and notifies reactive stream', () async {
      final service = BookingService();
      await service.createAppointment(
        AppointmentModel(
          id: 'b_update_test',
          studentId: 'SilentPanda42',
          counselorId: 'c1',
          sessionType: 'Video Call',
          startAt: DateTime(2026, 10, 25, 9, 30),
          endAt: DateTime(2026, 10, 25, 10, 20),
          status: 'confirmed',
        ),
      );

      // Reschedule
      final updated = await service.rescheduleBooking(
        'b_update_test',
        newDate: DateTime(2026, 10, 26),
        newTimeSlot: '03:30 PM',
      );

      expect(updated.startAt?.year, equals(2026));
      expect(updated.startAt?.month, equals(10));
      expect(updated.startAt?.day, equals(26));

      final verified = await service.getAppointmentById('b_update_test');
      expect(verified!.startAt?.day, equals(26));
    });

    test('Delete & Cancel: cancels session and removes record permanently', () async {
      final service = BookingService();
      await service.createAppointment(
        AppointmentModel(
          id: 'b_delete_test',
          studentId: 'SilentPanda42',
          counselorId: 'c1',
          sessionType: 'Video Call',
          startAt: DateTime(2026, 10, 28, 11, 0),
          endAt: DateTime(2026, 10, 28, 11, 50),
          status: 'confirmed',
        ),
      );

      // Cancel
      final cancelled = await service.cancelAppointment(
        'b_delete_test',
        cancellationReason: 'Class conflict',
      );
      expect(cancelled.isCancelled, isTrue);

      // Delete
      await service.deleteAppointment('b_delete_test');
      final afterDelete = await service.getAppointmentById('b_delete_test');
      expect(afterDelete, isNull);
    });

    test('PrivacyService: handles anonymous fallback without throwing', () async {
      final privacyService = PrivacyService();
      final settings = await privacyService.getPrivacySettings();
      expect(settings.currentPseudonym.isNotEmpty, isTrue);

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
      await bookingService.createAppointment(
        AppointmentModel(
          id: 'ui_bk_1',
          studentId: 'SilentPanda42',
          counselorId: 'counselor_sarah',
          sessionType: 'Video Call',
          startAt: DateTime(2026, 10, 18, 11, 0),
          endAt: DateTime(2026, 10, 18, 11, 50),
          status: 'confirmed',
          reason: 'Academic Stress',
          studentNotes: 'Passcode: STU-8821',
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
      final now = DateTime.now();
      final existingAppointment = AppointmentModel(
        id: 'edit_bk_9',
        studentId: 'SilentPanda42',
        counselorId: 'counselor_sarah',
        sessionType: 'Video Call',
        startAt: DateTime(now.year, now.month, now.day, 9, 30),
        endAt: DateTime(now.year, now.month, now.day, 10, 20),
        status: 'confirmed',
        reason: 'Anxiety',
      );
      await bookingService.createAppointment(existingAppointment);

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
            existingAppointment: existingAppointment,
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
      final updated = await bookingService.getAppointmentById('edit_bk_9');
      expect(updated!.startAt?.hour, equals(14));
    });
  });
}
