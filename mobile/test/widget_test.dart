// test/widget_test.dart
//
// Widget test verifying that LoginScreen renders the required form elements:
// - Email field
// - Password field
// - Login button

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pms_mobile/providers/auth_provider.dart';
import 'package:pms_mobile/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders email, password fields and login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Email field is present
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    // Verify Password field is present
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Verify Login button is present
    expect(find.widgetWithText(FilledButton, 'Log In'), findsOneWidget);
  });
}
