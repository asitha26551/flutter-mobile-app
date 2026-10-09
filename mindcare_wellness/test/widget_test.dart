import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare_wellness/main.dart';
import 'package:mindcare_wellness/screens/auth/login_screen.dart';

void main() {
  testWidgets('MindCareApp boots with configured home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MindCareApp(home: LoginScreen()));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
