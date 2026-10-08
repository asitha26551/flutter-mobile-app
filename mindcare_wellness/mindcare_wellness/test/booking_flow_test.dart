import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/models/booking_model.dart';
import 'package:mindcare_wellness/models/counselor_model.dart';
import 'package:mindcare_wellness/screens/booking/book_appointment_screen.dart';
import 'package:mindcare_wellness/screens/booking/booking_confirmation_screen.dart';
import 'package:mindcare_wellness/screens/counselors/counselor_directory_screen.dart';
import 'package:mindcare_wellness/services/booking_service.dart';
import 'package:mindcare_wellness/services/privacy_service.dart';

class _FakeBookingService extends BookingService {
  _FakeBookingService({List<CounselorModel>? counselors})
      : _counselorsList = counselors ??
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
                tags: ['Academic Stress', 'CBT'],
                availableSlots: ['11:00 AM'],
                isConfidentialSupported: true,
              ),
            ];

  final List<CounselorModel> _counselorsList;
  bool createCalled = false;
  BookingModel? lastCreatedBooking;

  @override
  Future<List<CounselorModel>> fetchCounselors(
      {bool onlyConfidentialSupported = false}) async {
    return _counselorsList;
  }

  @override
  Future<List<String>> fetchAvailableSlots(String counselorId,
      {DateTime? date}) async {
    final counselor = _counselorsList.firstWhere((c) => c.id == counselorId,
        orElse: () => _counselorsList.first);
    return counselor.availableSlots;
  }

  @override
  Future<BookingModel> createAnonymousBooking(BookingModel booking) async {
    createCalled = true;
    lastCreatedBooking = booking.copyWith(bookingId: 'test_bk_123');
    return lastCreatedBooking!;
  }
}

class _FakePrivacyService extends PrivacyService {
  @override
  String createPseudonym({dynamic random}) => 'QuietFalcon33';

  @override
  String createPasscode({String prefix = 'STU-', dynamic random}) =>
      'STU-7711';
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CounselorDirectoryScreen UI & Navigation Tests', () {
    testWidgets('renders search bar, filter chips, and counselor cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();

      await tester.pumpWidget(
        MaterialApp(
          home: CounselorDirectoryScreen(bookingService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      // Title & encrypted badge
      expect(find.text('Find a Counselor'), findsOneWidget);
      expect(find.text('Encrypted'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Filter chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Anxiety'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Academic Stress'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Available Today'), findsOneWidget);

      // Counselor cards
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('100% Confidential'), findsWidgets);
      expect(find.text('Book Session'), findsWidgets);
    });

    testWidgets('filters counselor list dynamically on search text entry',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();

      await tester.pumpWidget(
        MaterialApp(
          home: CounselorDirectoryScreen(bookingService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Sarah');
      await tester.pumpAndSettle();

      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsNothing);
    });

    testWidgets('tapping Book Session navigates to BookAppointmentScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();

      await tester.pumpWidget(
        MaterialApp(
          home: CounselorDirectoryScreen(bookingService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first "Book Session" button
      await tester.tap(find.text('Book Session').first);
      await tester.pumpAndSettle();

      // Should be on BookAppointmentScreen
      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);
    });
  });

  group('BookAppointmentScreen UI & Flow Tests', () {
    testWidgets('renders all required booking sections and format options',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();
      final fakePrivacy = _FakePrivacyService();
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
        availableSlots: ['09:30 AM', '02:00 PM'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookAppointmentScreen(
            counselor: counselor,
            bookingService: fakeService,
            privacyService: fakePrivacy,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Book Appointment'), findsOneWidget);
      expect(find.text('Dr. Sarah Perera'), findsOneWidget);

      // Formats
      expect(find.text('Text Chat'), findsOneWidget);
      expect(find.text('Audio Call'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);
      expect(find.text('In-Person'), findsOneWidget);

      // Calendar
      expect(find.text('Select Date'), findsOneWidget);

      // Slot groups (Morning / Afternoon)
      expect(find.text('Morning Slots'), findsOneWidget);
      expect(find.text('09:30 AM'), findsOneWidget);
      expect(find.text('Afternoon Slots'), findsOneWidget);
      expect(find.text('02:00 PM'), findsOneWidget);

      // Reason for visit chips
      expect(find.text('Academic Stress'), findsOneWidget);
      expect(find.text('Anxiety'), findsOneWidget);
      expect(find.text('Sleep Disruption'), findsOneWidget);
      expect(find.text('General Check-in'), findsOneWidget);

      // Bottom Button
      expect(find.text('Proceed to Review'), findsOneWidget);
    });

    testWidgets(
        'selecting slot and reason enables Proceed to Review and navigates to BookingConfirmationScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();
      final fakePrivacy = _FakePrivacyService();
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
        rating: '4.9',
        availableSlots: ['09:30 AM', '02:00 PM'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookAppointmentScreen(
            counselor: counselor,
            bookingService: fakeService,
            privacyService: fakePrivacy,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Time Slot
      await tester.tap(find.text('09:30 AM'));
      await tester.pumpAndSettle();

      // Select Reason
      await tester.tap(find.text('Academic Stress'));
      await tester.pumpAndSettle();

      // Tap Proceed to Review
      await tester.tap(find.text('Proceed to Review'));
      await tester.pumpAndSettle();

      // Verify we arrived at BookingConfirmationScreen
      expect(find.text('Booking Confirmation'), findsOneWidget);
      expect(find.text('Anonymous Booking Verified'), findsOneWidget);
      expect(find.text('QuietFalcon33'), findsOneWidget);
      expect(find.text('STU-7711'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });
  });

  group('BookingConfirmationScreen UI & Final Confirmation Tests', () {
    testWidgets('confirms booking and shows success screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = _FakeBookingService();
      const counselor = CounselorModel(
        id: 'c1',
        name: 'Dr. Sarah Perera',
        title: 'Senior Clinical Psychologist',
        location: 'Campus Wellness Center, Rm 204',
      );
      final booking = BookingModel(
        bookingId: '',
        counselorId: 'c1',
        counselorName: 'Dr. Sarah Perera',
        sessionFormat: 'Video Call',
        date: DateTime(2026, 10, 7),
        timeSlot: '09:30 AM',
        pseudonym: 'QuietFalcon33',
        passcode: 'STU-7711',
        reason: 'Academic Stress',
        isAnonymousMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingConfirmationScreen(
            booking: booking,
            counselor: counselor,
            bookingService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Booking'), findsOneWidget);

      // Tap Confirm Booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      // Verify service was called
      expect(fakeService.createCalled, isTrue);

      // Verify success screen
      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });
}
