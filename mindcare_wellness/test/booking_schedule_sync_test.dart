import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/counselor_models.dart';
import 'package:mindcare_wellness/screens/booking/book_appointment_screen.dart';
import 'package:mindcare_wellness/screens/booking/booking_confirmation_screen.dart';
import 'package:mindcare_wellness/screens/booking/my_schedule_screen.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    BookingService.resetDefaultInstance();
    PrivacyService.resetDefaultInstance();
  });

  tearDown(() {
    BookingService.resetDefaultInstance();
    PrivacyService.resetDefaultInstance();
  });

  testWidgets(
      'Confirmed booking appears immediately in MyScheduleScreen via shared services',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final counselor = CounselorModel.defaultCounselors.first;

    // 1. Render BookAppointmentScreen
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BookAppointmentScreen(
          counselor: counselor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select first slot & reason
    final firstSlot = counselor.availableSlots.first;
    await tester.tap(find.text(firstSlot));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Academic Stress'));
    await tester.pumpAndSettle();

    // Tap "Proceed to Review"
    final proceedBtn = find.widgetWithText(FilledButton, 'Proceed to Review');
    expect(proceedBtn, findsOneWidget);
    await tester.tap(proceedBtn);
    await tester.pumpAndSettle();

    // 2. We are now on BookingConfirmationScreen
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
    expect(find.text('Booking Confirmation'), findsOneWidget);

    // Tap "Confirm Booking"
    final confirmBtn = find.widgetWithText(FilledButton, 'Confirm Booking');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Success view is shown
    expect(find.text('Booking Confirmed!'), findsOneWidget);

    // Tap "View in My Schedule"
    final viewScheduleBtn =
        find.widgetWithText(FilledButton, 'View in My Schedule');
    expect(viewScheduleBtn, findsOneWidget);
    await tester.tap(viewScheduleBtn);
    await tester.pumpAndSettle();

    // 3. We are now on MyScheduleScreen
    expect(find.byType(MyScheduleScreen), findsOneWidget);
    expect(find.text('My Appointments'), findsOneWidget);

    // The booked session must be displayed and NOT empty state!
    expect(find.text('No Booked Sessions'), findsNothing);
    expect(find.text('No Upcoming Sessions'), findsNothing);
    expect(find.text(counselor.name), findsWidgets);
    expect(find.text('CONFIRMED'), findsWidgets);
  });

  testWidgets(
      'Confirmed booking appears in StudentDashboardScreen Schedule tab after navigating back',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bookingService = BookingService();
    final privacyService = PrivacyService();

    // Render StudentDashboardScreen
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StudentDashboardScreen(
          bookingService: bookingService,
          privacyService: privacyService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially, switch to Schedule tab (index 1)
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('No Booked Sessions'), findsOneWidget);

    // Switch back to Home (index 0)
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Tap "Book Now" on the first counselor
    final bookNowBtn = find.widgetWithText(FilledButton, 'Book Now').first;
    await tester.tap(bookNowBtn);
    await tester.pumpAndSettle();

    // In BookAppointmentScreen
    expect(find.byType(BookAppointmentScreen), findsOneWidget);
    final counselor = CounselorModel.defaultCounselors.first;
    final firstSlot = counselor.availableSlots.first;
    await tester.tap(find.text(firstSlot).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Academic Stress'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Proceed to Review'));
    await tester.pumpAndSettle();

    // In BookingConfirmationScreen, tap "Confirm Booking"
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm Booking'));
    await tester.pumpAndSettle();

    // Dismiss floating snackbar to allow direct button tap
    ScaffoldMessenger.of(tester.element(find.text('Booking Confirmed!'))).clearSnackBars();
    await tester.pumpAndSettle();

    // Tap "Back to Home"
    await tester.tap(find.widgetWithText(OutlinedButton, 'Back to Home'));
    await tester.pumpAndSettle();

    // Back on StudentDashboardScreen
    expect(find.byType(StudentDashboardScreen), findsOneWidget);

    // Switch to Schedule tab
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    // The booked appointment must now be rendered!
    expect(find.text('No Booked Sessions'), findsNothing);
    expect(find.text('CONFIRMED'), findsWidgets);
    expect(find.text(counselor.name), findsWidgets);
  });
}
