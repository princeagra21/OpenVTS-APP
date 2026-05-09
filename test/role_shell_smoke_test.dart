import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/shell/open_vts_app_shell.dart';
import 'package:open_vts/features/shell/role_nav_config.dart';

void main() {
  group('Role Shell Smoke Tests', () {
    testWidgets('superadmin shell builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.superadmin,
            title: 'Superadmin Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'SA',
            showBottomBar: false,
            showLeftAvatar: false, // Show title instead of avatar
            child: const Center(child: Text('Superadmin content')),
          ),
        ),
      );

      expect(find.text('Superadmin Shell'), findsOneWidget);
      expect(find.text('Superadmin content'), findsOneWidget);
      expect(find.byType(OpenVtsAppShell), findsOneWidget);
    });

    testWidgets('admin shell builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.admin,
            title: 'Admin Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'A',
            showBottomBar: false,
            showLeftAvatar: false,
            child: const Center(child: Text('Admin content')),
          ),
        ),
      );

      expect(find.text('Admin Shell'), findsOneWidget);
      expect(find.text('Admin content'), findsOneWidget);
      expect(find.byType(OpenVtsAppShell), findsOneWidget);
    });

    testWidgets('user shell builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.user,
            title: 'User Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'U',
            showBottomBar: false,
            showLeftAvatar: false,
            child: const Center(child: Text('User content')),
          ),
        ),
      );

      expect(find.text('Test subtitle'), findsOneWidget); // User uses home style, shows subtitle
      expect(find.text('User content'), findsOneWidget);
      expect(find.byType(OpenVtsAppShell), findsOneWidget);
    });

    testWidgets('shell with custom top bar builds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.user,
            title: 'Custom Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'C',
            showLeftAvatar: false,
            showBottomBar: false,
            customTopBar: Container(
              height: 50,
              color: Colors.blue,
              child: const Center(child: Text('Custom Top Bar')),
            ),
            child: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.text('Custom Top Bar'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shell without app bar builds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.user,
            title: 'No App Bar Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'N',
            showAppBar: false,
            showBottomBar: false,
            child: const Center(child: Text('Content without app bar')),
          ),
        ),
      );

      expect(find.text('No App Bar Shell'), findsNothing);
      expect(find.text('Content without app bar'), findsOneWidget);
    });

    testWidgets('shell without bottom bar builds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OpenVtsAppShell(
            role: OpenVtsRole.user,
            title: 'No Bottom Bar Shell',
            subtitle: 'Test subtitle',
            leftAvatarText: 'B',
            showLeftAvatar: false,
            showBottomBar: false,
            child: const Center(child: Text('Content without bottom bar')),
          ),
        ),
      );

      expect(find.text('Test subtitle'), findsOneWidget); // User shows subtitle in home style
      expect(find.text('Content without bottom bar'), findsOneWidget);
    });
  });
}