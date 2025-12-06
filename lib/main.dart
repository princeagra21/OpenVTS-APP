import 'package:fleet_stack/components/profile/profile_screen.dart';
import 'package:fleet_stack/components/vehicle/VehicleDetailsScreen.dart';
import 'package:fleet_stack/components/vehicle/vehicle_screen.dart';
import 'package:fleet_stack/components/vehicle/widget/add_new_vehicle.dart';
import 'package:fleet_stack/screens/admin/administrator_details_screen.dart';
import 'package:fleet_stack/screens/admin/admins_screen.dart';
import 'package:fleet_stack/screens/map/map_screen.dart';
import 'package:fleet_stack/screens/more/more_screen.dart';
import 'package:fleet_stack/screens/setting/setting_screen.dart';
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
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/admins/details/:id',
      name: 'adminDetails',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdministratorDetailsScreen(id: id!);
      },
    ),

    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),

    /// 🚗 Vehicle list screen
    GoRoute(
      path: '/vehicles',
      builder: (_, __) => const VehicleScreen(),
    ),

    /// 🚗 Add new vehicle screen
    GoRoute(
      path: '/vehicles/add',
      builder: (_, __) => const AddVehicleScreen(),
    ),

    GoRoute(
      path: '/more',
      builder: (_, __) => const MoreScreen(),
    ),

    GoRoute(
      path: '/map',
      builder: (_, __) => const MapScreen(),
    ),

    /// 🚗 Vehicle details screen
    GoRoute(
      path: '/vehicles/details/:id',
      name: 'vehicleDetails',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return VehicleDetailsScreen(id: id!);
      },
    ),
  ],
);

void main() {
  runApp(const MyApp());
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

          /// 👇 No DevicePreview here anymore
          builder: (context, widget) => widget!,

          /// 👇 GoRouter integration
          routerConfig: router,

          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          ),
        );
      },
    );
  }
}
