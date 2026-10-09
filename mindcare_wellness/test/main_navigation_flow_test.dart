import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/appointment_model.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/screens/booking/book_appointment_screen.dart';
import 'package:mindcare_wellness/screens/booking/booking_confirmation_screen.dart';
import 'package:mindcare_wellness/screens/counselors/counselor_directory_screen.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';
import 'package:mindcare_wellness/screens/privacy/privacy_settings_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

class _FlowBookingService extends BookingService {
  final List<CounselorModel> counselors = const [
    CounselorModel(
      id: 'c1',
      name: 'Dr. Sarah Perera',
      title: 'Senior Clinical Psychologist',
      location: 'Campus Wellness Center, Rm 204',
      rating: '4.9',
      reviewCount: 128,
      tags: ['Anxiety', 'Academic Stress'],
      availableSlots: ['09:30 AM', '11:00 AM', '02:00 PM'],
      isConfidentialSupported: true,
    ),
  ];

  bool bookingSaved = false;

  @override
  Future<List<CounselorModel>> fetchCounselors(
      {bool onlyConfidentialSupported = false}) async {
    return counselors;
  }

  @override
  Future<List<String>> fetchAvailableSlots(
    String counselorId, {
    DateTime? date,
  }) async {
    return ['09:30 AM', '11:00 AM', '02:00 PM'];
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    bookingSaved = true;
    return appointment.copyWith(id: 'saved-bk-999');
  }
}

class _FlowPrivacyService extends PrivacyService {
  @override
  String createPseudonym({dynamic random}) => 'SilentPanda42';

  @override
  String createPasscode({String prefix = 'STU-', dynamic random}) => 'STU-8821';

  @override
  Future<PrivacySettingsModel> getPrivacySettings([String? uid]) async {
    return const PrivacySettingsModel(
      hideRealName: true,
      currentPseudonym: 'SilentPanda42',
      passcode: 'STU-8821',
    );
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
      'Complete Navigation Flow: Dashboard -> Directory -> Appointment -> Confirmation -> Dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bookingService = _FlowBookingService();
    final privacyService = _FlowPrivacyService();

    await tester.pumpWidget(
      MaterialApp(
        title: 'MindCare Wellness',
        theme: buildAppTheme(),
        home: StudentDashboardScreen(
          bookingService: bookingService,
          privacyService: privacyService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify StudentDashboardScreen elements
    expect(find.text('MindCare Wellness'), findsOneWidget);
    expect(find.text('Privacy Mode: Active'), findsOneWidget);
    expect(find.text('Book\nCounselor'), findsOneWidget);
    expect(find.text('Privacy\nSettings'), findsOneWidget);

    // 2. Tap Quick Action: "Book Counselor" -> Navigates to CounselorDirectoryScreen
    await tester.tap(find.text('Book\nCounselor'));
    await tester.pumpAndSettle();

    expect(find.byType(CounselorDirectoryScreen), findsOneWidget);
    expect(find.text('Find a Counselor'), findsOneWidget);
    expect(find.text('Dr. Sarah Perera'), findsWidgets);

    // 3. In Counselor Directory Screen: Tap "Book Session" -> Navigates to BookAppointmentScreen
    final bookSessionButton = find.widgetWithText(FilledButton, 'Book Session').first;
    await tester.tap(bookSessionButton);
    await tester.pumpAndSettle();

    expect(find.byType(BookAppointmentScreen), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);

    // 4. In Book Appointment Screen: Select Slot and Reason, then tap "Proceed to Review"
    // Tap slot "09:30 AM"
    await tester.tap(find.text('09:30 AM'));
    await tester.pumpAndSettle();

    // Tap reason "Academic Stress"
    await tester.tap(find.text('Academic Stress'));
    await tester.pumpAndSettle();

    // Tap "Proceed to Review"
    await tester.tap(find.text('Proceed to Review'));
    await tester.pumpAndSettle();

    // 5. In Booking Confirmation Screen:
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    expect(find.text('Anonymous Booking Verified'), findsOneWidget);
    expect(find.text('SilentPanda42'), findsOneWidget);
    expect(find.text('STU-8821'), findsOneWidget);
    expect(find.textContaining('09:30 AM'), findsWidgets);

    // Tap "Confirm Booking"
    await tester.tap(find.text('Confirm Booking'));
    await tester.pumpAndSettle();

    // Booking saved & SnackBar/Confirmation displayed
    expect(bookingService.bookingSaved, isTrue);
    expect(find.text('Booking Confirmed!'), findsOneWidget);

    // Dismiss floating SnackBar to ensure unobstructed click
    ScaffoldMessenger.of(
      tester.element(find.byType(BookingConfirmationScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Tap "Back to Home" -> Returns to StudentDashboardScreen
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.byType(StudentDashboardScreen), findsOneWidget);
  });

  testWidgets(
      'Dashboard Navigation: Quick Action Privacy Settings -> PrivacySettingsScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bookingService = _FlowBookingService();
    final privacyService = _FlowPrivacyService();

    await tester.pumpWidget(
      MaterialApp(
        title: 'MindCare Wellness',
        theme: buildAppTheme(),
        home: StudentDashboardScreen(
          bookingService: bookingService,
          privacyService: privacyService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Quick Action "Privacy Settings"
    await tester.tap(find.text('Privacy\nSettings'));
    await tester.pumpAndSettle();

    // Verify on PrivacyControlsScreen / PrivacySettingsScreen
    expect(find.byType(PrivacySettingsScreen), findsOneWidget);
    expect(find.text('Privacy & Identity Controls'), findsOneWidget);
  });
}
