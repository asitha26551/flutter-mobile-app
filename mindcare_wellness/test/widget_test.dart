import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/main.dart';
import 'package:mindcare_wellness/screens/dashboard/student_dashboard_screen.dart';

void main() {
  testWidgets('MindCareApp boots with StudentDashboardScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MindCareApp());
    expect(find.byType(StudentDashboardScreen), findsOneWidget);
  });
}
