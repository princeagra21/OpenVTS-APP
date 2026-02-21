import 'dart:convert';

import 'package:device_preview/device_preview.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
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

String _targetPathForRole(String? backendRole) {
  final normalized = (backendRole ?? '').trim().toLowerCase();
  if (normalized.contains('super')) return '/superadmin/home';
  if (normalized.contains('admin')) return '/admin/home';
  if (normalized.contains('driver')) return '/user/home';
  if (normalized.contains('user')) return '/user/home';
  return '/user/home';
}

Map<String, dynamic>? _decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded.cast());
  } catch (_) {
    return null;
  }
  return null;
}

bool _isTokenExpired(String token) {
  final payload = _decodeJwtPayload(token);
  if (payload == null) return false;

  final expRaw = payload['exp'];
  int? expSeconds;
  if (expRaw is int) {
    expSeconds = expRaw;
  } else if (expRaw is num) {
    expSeconds = expRaw.toInt();
  } else if (expRaw is String) {
    expSeconds = int.tryParse(expRaw);
  }

  if (expSeconds == null) return false;
  final expiry = DateTime.fromMillisecondsSinceEpoch(
    expSeconds * 1000,
    isUtc: true,
  );
  return DateTime.now().toUtc().isAfter(expiry);
}

String? _coerceRoleString(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final s = value.trim();
    return s.isEmpty ? null : s;
  }
  if (value is List) {
    for (final item in value) {
      final s = _coerceRoleString(item);
      if (s != null) return s;
    }
  }
  if (value is Map) {
    final s = _coerceRoleString(
      value['name'] ??
          value['role'] ??
          value['type'] ??
          value['slug'] ??
          value['code'],
    );
    if (s != null) return s;
  }
  final asString = value.toString().trim();
  return asString.isEmpty ? null : asString;
}

String? _extractRoleFromToken(String token) {
  final payload = _decodeJwtPayload(token);
  if (payload == null) return null;

  String? pickFromMap(Map map) {
    final direct = [
      map['role'],
      map['userRole'],
      map['userType'],
      map['roleType'],
      map['type'],
    ];
    for (final v in direct) {
      final role = _coerceRoleString(v);
      if (role != null) return role;
    }

    for (final key in const ['data', 'user', 'account']) {
      final nested = map[key];
      if (nested is Map) {
        final role = pickFromMap(nested);
        if (role != null) return role;
      }
    }
    return null;
  }

  return pickFromMap(payload);
}

Future<String> _resolveInitialLocation() async {
  final storage = TokenStorage.defaultInstance();
  final token = await storage.readAccessToken();

  if (token == null || token.trim().isEmpty) return '/onboarding';

  if (_isTokenExpired(token)) {
    await storage.clear();
    return '/onboarding';
  }

  final role = _extractRoleFromToken(token);
  return _targetPathForRole(role);
}

/// ROUTER
GoRouter buildRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    /// ======================
    /// 🌍 GLOBAL ROUTES
    /// ======================
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/', builder: (_, __) => const LoginScreen()),

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
    final colorValue =
        prefs.getInt("brandColor") ?? AppTheme.defaultBrand.value;

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
  final initialLocation = await _resolveInitialLocation();
  final enableDevicePreview =
      !kReleaseMode ||
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android;
  if (kDebugMode) {
    debugPrint('[AuthBootstrap] initialLocation=$initialLocation');
  }
  final appRouter = buildRouter(initialLocation);

  runApp(
    enableDevicePreview
        ? DevicePreview(
            enabled: true,
            builder: (context) => MyApp(
              router: appRouter,
              enableDevicePreview: enableDevicePreview,
            ),
          )
        : MyApp(router: appRouter, enableDevicePreview: enableDevicePreview),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  final bool enableDevicePreview;

  const MyApp({
    super.key,
    required this.router,
    this.enableDevicePreview = false,
  });

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

              locale: enableDevicePreview
                  ? DevicePreview.locale(context)
                  : null,
              builder: enableDevicePreview ? DevicePreview.appBuilder : null,

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
