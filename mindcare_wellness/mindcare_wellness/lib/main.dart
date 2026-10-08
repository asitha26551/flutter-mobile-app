import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/booking_model.dart';
import 'models/counselor_model.dart';
import 'screens/booking/book_appointment_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/booking/my_schedule_screen.dart';
import 'screens/counselors/counselor_directory_screen.dart';
import 'screens/dashboard/student_dashboard_screen.dart';
import 'screens/privacy/privacy_settings_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization fallback (running with offline/in-memory services): $e',
    );
  }
  runApp(const MindCareApp());
}

class MindCareApp extends StatelessWidget {
  const MindCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCare Wellness',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const StudentDashboardScreen(),
      routes: {
        '/dashboard': (context) => const StudentDashboardScreen(),
        '/counselors': (context) => const CounselorDirectoryScreen(),
        '/privacy': (context) => const PrivacySettingsScreen(),
        '/schedule': (context) => const MyScheduleScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book-appointment') {
          final counselor = settings.arguments as CounselorModel?;
          if (counselor != null) {
            return MaterialPageRoute(
              builder: (context) => BookAppointmentScreen(counselor: counselor),
            );
          }
        } else if (settings.name == '/booking-confirmation') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args['booking'] is BookingModel) {
            return MaterialPageRoute(
              builder: (context) => BookingConfirmationScreen(
                booking: args['booking'] as BookingModel,
                counselor: args['counselor'] as CounselorModel?,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
