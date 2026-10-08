// test/widget_test.dart
//
// Basic smoke test: checks that the app starts without crashing.
// We can't fully test the router here because it depends on async
// providers, so we just verify the widget tree inflates.

import 'package:flutter_test/flutter_test.dart';
import 'package:pms_mobile/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build the app and process one frame.
    await tester.pumpWidget(const ProjectManagerApp());

    // The app should render something (the splash screen or a loading indicator).
    // We don't assert specific text because auth state is async.
    expect(find.byType(ProjectManagerApp), findsOneWidget);
  });
}
