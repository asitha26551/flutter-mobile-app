import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/appointment_model.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/screens/booking/booking_confirmation_screen.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';

class _MockBookingService extends BookingService {
  _MockBookingService({List<CounselorModel>? counselors})
      : _counselors = counselors ??
            const [
              CounselorModel(
                id: 'c1',
                name: 'Dr. Sarah Perera',
                title: 'Senior Clinical Psychologist',
                location: 'Campus Wellness Center, Rm 204',
                rating: '4.9',
                reviewCount: 128,
                tags: ['Anxiety', 'Academic Stress'],
                availableSlots: ['09:30 AM', '02:00 PM'],
                isConfidentialSupported: true,
              ),
              CounselorModel(
                id: 'c2',
                name: 'Dr. Marcus Vance',
                title: 'Neuropsychologist',
                location: 'Health Science Bldg, Suite 102',
                rating: '4.85',
                reviewCount: 110,
                tags: ['Academic Stress'],
                availableSlots: ['11:00 AM'],
                isConfidentialSupported: true,
              ),
            ];

  final List<CounselorModel> _counselors;
  bool saveCalled = false;
  AppointmentModel? savedAppointment;

  @override
  Future<List<CounselorModel>> fetchCounselors(
      {bool onlyConfidentialSupported = false}) async {
    return _counselors;
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    saveCalled = true;
    savedAppointment = appointment.copyWith(id: 'saved_apt_777');
    return savedAppointment!;
  }
}

class _MockPrivacyService extends PrivacyService {
  @override
  String createPseudonym({dynamic random}) => 'SilentPanda42';

  @override
  String createPasscode({String prefix = 'STU-', dynamic random}) =>
      'STU-8821';
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('STEP 5: BookingConfirmationScreen UI & Features', () {
    testWidgets('renders all required cards, checklist, badges, and button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockBookingService = _MockBookingService();
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
      );
      final appointment = AppointmentModel(
        id: '',
        studentId: 'SilentPanda42',
        counselorId: 'c1',
        startAt: DateTime(2026, 10, 7, 9, 30),
        endAt: DateTime(2026, 10, 7, 10, 20),
        sessionType: 'Video Call',
        status: 'confirmed',
        reason: 'Academic Stress',
        location: 'Campus Wellness Center, Rm 204',
        studentNotes: 'Passcode: STU-8821',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingConfirmationScreen(
            appointment: appointment,
            counselor: counselor,
            bookingService: mockBookingService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. "Anonymous Booking Verified" top status card
      expect(find.text('Anonymous Booking Verified'), findsOneWidget);

      // 2. Appointment details summary
      expect(find.text('APPOINTMENT DETAILS'), findsOneWidget);
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('Senior Clinical Psychologist'), findsOneWidget);
      expect(find.text('Campus Wellness Center, Rm 204'), findsOneWidget);
      expect(find.text('Session Format'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);
      expect(find.textContaining('October 7, 2026 at 09:30 AM'), findsOneWidget);
      expect(find.text('Academic Stress'), findsOneWidget);

      // 3. Active Pseudonym display badge
      expect(find.text('Active Pseudonym'), findsOneWidget);
      expect(find.text('SilentPanda42'), findsOneWidget);

      // 4. Anonymous Passcode card displaying 'STU-8821' with "Copy Code" button
      expect(find.text('ANONYMOUS PASSCODE'), findsOneWidget);
      expect(find.text('STU-8821'), findsOneWidget);
      expect(find.text('Copy Code'), findsOneWidget);

      // 5. Confidentiality rules checklist
      expect(find.text('CONFIDENTIALITY RULES CHECKLIST'), findsOneWidget);
      expect(find.text('100% Zero-Data Disclosure'), findsOneWidget);
      expect(find.text('Separated Clinical Records'), findsOneWidget);
      expect(find.text('Encrypted Ephemeral Access'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));

      // 6. Full-width Emerald Green "Confirm Booking" button
      expect(find.text('Confirm Booking'), findsOneWidget);

      // Tap Confirm Booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(mockBookingService.saveCalled, isTrue);
      expect(find.text('Booking Confirmed!'), findsOneWidget);
    });

    testWidgets('Copy Code button copies passcode to clipboard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appointment = AppointmentModel(
        id: '',
        studentId: 'SilentPanda42',
        counselorId: 'c1',
        startAt: DateTime(2026, 10, 7, 11, 0),
        endAt: DateTime(2026, 10, 7, 11, 50),
        sessionType: 'Audio Call',
        status: 'confirmed',
        reason: 'Anxiety',
        studentNotes: 'Passcode: STU-8821',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingConfirmationScreen(
            appointment: appointment,
            bookingService: _MockBookingService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Copy Code
      await tester.tap(find.text('Copy Code'));
      await tester.pumpAndSettle();

      expect(find.text('Passcode copied to clipboard!'), findsOneWidget);
    });
  });

  group('STEP 5: StudentDashboardScreen UI & Navigation', () {
    testWidgets('renders Privacy Mode indicator, mood emojis, quick actions, and navbar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockBooking = _MockBookingService();
      final mockPrivacy = _MockPrivacyService();

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            bookingService: mockBooking,
            privacyService: mockPrivacy,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar: "Privacy Mode: Active" status indicator
      expect(find.text('Privacy Mode: Active'), findsOneWidget);

      // Mood emoji selector: "How are you feeling today?"
      expect(find.text('How are you feeling today?'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      expect(find.text('Stressed'), findsOneWidget);

      // Quick Action cards: "Book Counselor", "My Schedule", "Privacy Settings"
      expect(find.text('Book\nCounselor'), findsOneWidget);
      expect(find.text('My\nSchedule'), findsOneWidget);
      expect(find.text('Privacy\nSettings'), findsOneWidget);

      // Recommended Counselors list with "Book Now" shortcuts
      expect(find.text('Recommended Counselors'), findsOneWidget);
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('Book Now'), findsWidgets);

      // Bottom Navigation Bar: Home, Schedule, Counselors, Mood Log
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Counselors'), findsOneWidget);
      expect(find.text('Mood Log'), findsOneWidget);
    });

    testWidgets('tapping mood emoji logs feedback', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            bookingService: _MockBookingService(),
            privacyService: _MockPrivacyService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Great' emoji
      await tester.tap(find.text('Great'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mood logged anonymously: Great'), findsOneWidget);
    });

    testWidgets('tapping Book Now shortcut navigates to BookAppointmentScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            bookingService: _MockBookingService(),
            privacyService: _MockPrivacyService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first "Book Now" button
      await tester.tap(find.text('Book Now').first);
      await tester.pumpAndSettle();

      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
    });

    testWidgets('tapping BottomNavigationBar tabs switches view',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDashboardScreen(
            bookingService: _MockBookingService(),
            privacyService: _MockPrivacyService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Schedule' tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('My Appointments'), findsOneWidget);

      // Tap 'Mood Log' tab
      await tester.tap(find.text('Mood Log'));
      await tester.pumpAndSettle();
      expect(find.text('Mood Tracker & Check-in'), findsOneWidget);
    });
  });
}
