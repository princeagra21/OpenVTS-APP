import 'package:device_preview/device_preview.dart';
import 'package:fleet_stack/screens/admin/administrator_details_screen.dart';
import 'package:fleet_stack/screens/admin/admins_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';

/// 👇 Define router here
final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),

    GoRoute(
  path: '/admins',
  builder: (_, __) => const AdminScreen(),
),

GoRoute(
  path: '/admins/details/:id',
  name: 'adminDetails',
  builder: (context, state) {
    final id = state.pathParameters['id']; // <-- Correct
    return AdministratorDetailsScreen(id: id!);
  },
),




    // ADD OTHERS LATER
    // GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
    // GoRoute(path: '/admins', builder: (_, __) => const AdminsScreen()),
    // GoRoute(path: '/vehicles', builder: (_, __) => const VehiclesScreen()),
    // GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
  ],
);

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,

          /// 👇 Required for DevicePreview
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,

          /// 👇 GoRouter integration
          routerConfig: router,

          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          ),
        );
      },

      /// ❌ Removed child: HomeScreen() — router decides this
    );
  }
}
