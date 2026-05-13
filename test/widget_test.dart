import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/app.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/router/app_router.dart';

void main() {
  testWidgets('App builds (smoke test)', (WidgetTester tester) async {
    AppContainer.initialize();
    await tester.pumpWidget(
      FleetStackApp(router: AppRouter.build(initialLocation: '/onboarding')),
    );
    await tester.pump(const Duration(milliseconds: 16));
  });
}
