import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/appointment_model.dart';
import 'models/counselor_models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/booking/book_appointment_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/student/student_appointments_screen.dart';
import 'screens/counselors/counselor_directory_screen.dart';
import 'screens/dashboard/student_dashboard_screen.dart';
import 'screens/privacy/privacy_controls_screen.dart';
import 'screens/student/weekly_wellbeing_screen.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/mindcare_intro_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MindCareApp());
}

class MindCareApp extends StatelessWidget {
  const MindCareApp({this.home, super.key});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindCare Wellness',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home ?? const MindCareIntroFlow(),
      routes: {
        '/dashboard': (context) => const StudentDashboardScreen(),
        '/student-dashboard': (context) => const StudentDashboardScreen(),
        '/counselors': (context) => const CounselorDirectoryScreen(),
        '/directory': (context) => const CounselorDirectoryScreen(),
        '/schedule': (context) => StudentAppointmentsScreen(),
        '/my-schedule': (context) => StudentAppointmentsScreen(),
        '/privacy': (context) => const PrivacyControlsScreen(),
        '/privacy-settings': (context) => const PrivacyControlsScreen(),
        '/mood-log': (context) => WeeklyWellbeingScreen(),
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book-appointment' || settings.name == '/book') {
          if (settings.arguments is! CounselorModel) {
            return MaterialPageRoute(
              builder: (_) => const CounselorDirectoryScreen(),
              settings: settings,
            );
          }
          final counselor = settings.arguments as CounselorModel;
          return MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(counselor: counselor),
            settings: settings,
          );
        }
        if (settings.name == '/booking-confirmation' &&
            settings.arguments is AppointmentModel) {
          return MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              appointment: settings.arguments as AppointmentModel,
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
