import 'package:device_preview/device_preview.dart';
import 'package:fleet_stack/login_screen.dart';
import 'package:fleet_stack/modules/user/router/user_routes.dart';
import 'package:fleet_stack/onboarding_screen.dart';
import 'package:fleet_stack/modules/superadmin/router/superadmin_routes.dart';
import 'package:fleet_stack/modules/admin/router/admin_routes.dart';
import 'package:fleet_stack/modules/superadmin/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ROUTER
final GoRouter router = GoRouter(
  initialLocation: '/onboarding',
  routes: [

    /// ======================
    /// 🌍 GLOBAL ROUTES
    /// ======================
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (_, __) => const LoginScreen(),
    ),


    /// ======================
    /// 👑 SUPERADMIN ROUTES
    /// ======================
    ...superAdminRoutes,

    /// ======================
    /// 🔑 ADMIN ROUTES
    /// ======================
    ...adminRoutes,

    /// ======================
    ///  USER ROUTES
    /// ======================
    ...userRoutes,
  ],
);


/// ==============================
///  THEME CONTROLLER + CACHE
/// ==============================
class ThemeController {
  ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  ValueNotifier<Color> brandColor = ValueNotifier(AppTheme.defaultBrand);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool("isDark") ?? false;
    final colorValue = prefs.getInt("brandColor") ?? AppTheme.defaultBrand.value;

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    brandColor.value = Color(colorValue);
  }

  void setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDark", isDark);

    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

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
  await themeController.loadTheme();

  runApp(
    kReleaseMode
        ? const MyApp()
        : DevicePreview(
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

              // Only active in debug mode
              locale: kReleaseMode ? null : DevicePreview.locale(context),
              builder: kReleaseMode ? null : DevicePreview.appBuilder,

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