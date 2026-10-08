import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindcare_wellness/screens/auth/login_screen.dart';
import 'package:mindcare_wellness/screens/auth/register_screen.dart';
import 'package:mindcare_wellness/theme/app_theme.dart';

void main() {
  testWidgets('login screen exposes the client authentication flow', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const LoginScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
