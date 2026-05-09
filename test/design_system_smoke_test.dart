import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/design_system/components/open_vts_button.dart';
import 'package:open_vts/design_system/components/open_vts_text_field.dart';
import 'package:open_vts/design_system/components/open_vts_card.dart';
import 'package:open_vts/design_system/components/open_vts_feedback.dart';
import 'package:open_vts/design_system/components/open_vts_dialog.dart';

void main() {
  group('Design System Smoke Tests', () {
    testWidgets('OpenVtsButton builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenVtsButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(OpenVtsButton), findsOneWidget);
    });

    testWidgets('OpenVtsTextField builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenVtsTextField(
              hintText: 'Test hint',
            ),
          ),
        ),
      );

      expect(find.byType(OpenVtsTextField), findsOneWidget);
    });

    testWidgets('OpenVtsCard builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenVtsCard(
              child: const Text('Test content'),
            ),
          ),
        ),
      );

      expect(find.text('Test content'), findsOneWidget);
      expect(find.byType(OpenVtsCard), findsOneWidget);
    });

    testWidgets('OpenVtsFeedback.success shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => OpenVtsFeedback.success(context, 'Success message'),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Success message'), findsOneWidget);
    });

    testWidgets('OpenVtsFeedback.error shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => OpenVtsFeedback.error(context, 'Error message'),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('OpenVtsDialog builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => OpenVtsDialog(
                    title: 'Test Dialog',
                    content: const Text('Dialog content'),
                    actions: [
                      OpenVtsButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}