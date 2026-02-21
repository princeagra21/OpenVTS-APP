// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_stack/main.dart';

void main() {
  testWidgets('App builds (smoke test)', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(router: buildRouter('/onboarding')));
    // Avoid pumpAndSettle here; the app has ongoing animations/routes that can
    // keep the test harness busy indefinitely.
    await tester.pump(const Duration(milliseconds: 16));
  });
}
