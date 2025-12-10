import 'package:device_preview/device_preview.dart';
import 'package:fleet_stack/components/admin/api_config/api_config.dart';
import 'package:fleet_stack/components/admin/application_setting/application_setting.dart';
import 'package:fleet_stack/components/admin/branding/branding_screen.dart';
import 'package:fleet_stack/components/admin/calender/calender_screen.dart';
import 'package:fleet_stack/components/admin/email_template_setting/email_template.dart';
import 'package:fleet_stack/components/admin/localization/localization.dart';
import 'package:fleet_stack/components/admin/payment_gateway_setting/payment_gateway_details.dart';
import 'package:fleet_stack/components/admin/payment_gateway_setting/payment_gateway_setting.dart';
import 'package:fleet_stack/components/admin/policy_edit/policy_edit.dart';
import 'package:fleet_stack/components/admin/push_notification_template/push_notification_template.dart';
import 'package:fleet_stack/components/admin/role/role.dart';
import 'package:fleet_stack/components/admin/server_status/server_status.dart';
import 'package:fleet_stack/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:fleet_stack/components/admin/ssl/ssl.dart';
import 'package:fleet_stack/components/admin/support/support.dart';
import 'package:fleet_stack/components/branding/branding_settings_screen.dart';
import 'package:fleet_stack/components/profile/profile_screen.dart';
import 'package:fleet_stack/components/vehicle/VehicleDetailsScreen.dart';
import 'package:fleet_stack/components/vehicle/vehicle_screen.dart';
import 'package:fleet_stack/components/vehicle/widget/add_new_vehicle.dart';
import 'package:fleet_stack/screens/admin/administrator_details_screen.dart';
import 'package:fleet_stack/screens/admin/admins_screen.dart';
import 'package:fleet_stack/screens/map/map_screen.dart';
import 'package:fleet_stack/screens/more/more_screen.dart';
import 'package:fleet_stack/screens/setting/setting_screen.dart';
import 'package:fleet_stack/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home/home_screen.dart';

/// ROUTER
final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/admins', builder: (_, __) => const AdminScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/admins/details/:id',
      name: 'adminDetails',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return AdministratorDetailsScreen(id: id!);
      },
    ),

    GoRoute(path: '/branding', builder: (_, __) => const BrandingScreen()),
    GoRoute(path: '/white-label', builder: (_, __) => const BrandingSettingsScreen()),
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/api-config', builder: (_, __) => const ApiConfigSettingsScreen()),
    GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),

    GoRoute(path: '/smtp-settings', builder: (_, __) => const SmtpConfigSettingsScreen()),
    GoRoute(path: '/localization', builder: (_, __) => const LocalizationSettingsScreen()),
    GoRoute(path: '/application-settings', builder: (_, __) => const ApplicationSettingsScreen()),
    GoRoute(path: '/email-settings', builder: (_, __) => const EmailTemplateSettingsScreen()),

    GoRoute(
      path: '/payment-gateway/:id',
      builder: (context, state) {
        final gatewayId = state.pathParameters['id']!;
        return PaymentGatewayDetailsScreen(gatewayId: gatewayId);
      },
    ),

    GoRoute(path: '/payment-gateway', builder: (_, __) => const PaymentGatewaySettingsScreen()),
    GoRoute(path: '/notification-settings', builder: (_, __) => const PushNotificationTemplateSettingsScreen()),

    GoRoute(path: '/vehicles', builder: (_, __) => const VehicleScreen()),
    GoRoute(path: '/vehicles/add', builder: (_, __) => const AddVehicleScreen()),

    GoRoute(path: '/calendar', builder: (_, __) => const EventCalendarScreen()),
    GoRoute(path: '/server', builder: (_, __) => const ServerStatusScreen()),
    GoRoute(path: '/ssl', builder: (_, __) => const SSLManagementScreen()),
    GoRoute(path: '/roles', builder: (_, __) => const RolesScreen()),
    GoRoute(path: '/user-policy', builder: (_, __) => const PolicyEditScreen()),
    GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
    GoRoute(path: '/map', builder: (_, __) => const MapScreen()),

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

/// ==============================
///  THEME CONTROLLER + CACHE
/// ==============================
class ThemeController {
  ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  ValueNotifier<Color> brandColor = ValueNotifier(AppTheme.defaultBrand);

  /// Load cached saved values
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool("isDark") ?? false;
    final colorValue = prefs.getInt("brandColor") ?? AppTheme.defaultBrand.value;

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    brandColor.value = Color(colorValue);
  }

  /// Save dark/light mode
  void setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDark", isDark);

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Save brand color
  void setBrand(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("brandColor", color.value);

    brandColor.value = color;
  }
}

final themeController = ThemeController();

/// LISTENABLE BUILDER 2
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) {
            return builder(context, a, b, null);
          },
        );
      },
    );
  }
}

/// ===========================
///    MAIN APP
/// ===========================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Load theme cache before runApp
  await themeController.loadTheme();

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
        return ValueListenableBuilder2<ThemeMode, Color>(
          first: themeController.themeMode,
          second: themeController.brandColor,
          builder: (_, mode, brand, __) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              useInheritedMediaQuery: true,
              locale: DevicePreview.locale(context),
              builder: DevicePreview.appBuilder,
              routerConfig: router,
              theme: AppTheme.light(brand),
              darkTheme: AppTheme.dark(brand),
              themeMode: mode,
            );
          },
        );
      },
    );
  }
}
