import 'dart:convert';
import 'dart:async';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/navigation/app_routes.dart';

import 'package:device_preview/device_preview.dart';
import 'package:open_vts/core/auth/route_guard.dart';
import 'package:open_vts/core/auth/session_expired_bus.dart';
import 'package:open_vts/core/config/api_base_url_config.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:open_vts/login_screen.dart';
import 'package:open_vts/modules/user/router/user_routes.dart';
import 'package:open_vts/onboarding_screen.dart';
import 'package:open_vts/modules/superadmin/router/superadmin_routes.dart';
import 'package:open_vts/modules/admin/router/admin_routes.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _targetPathForRole(String? backendRole) {
  return RouteGuard.defaultRouteForRole(backendRole);
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
  final storage = AppContainer.instance.tokenStorage;
  final token = await storage.readAccessToken();

  if (token == null || token.trim().isEmpty) return AppRoutes.onboarding;

  if (_isTokenExpired(token)) {
    await storage.clear();
    return AppRoutes.onboarding;
  }

  final role = _extractRoleFromToken(token);
  final targetPath = _targetPathForRole(role);
  if (targetPath == AppRoutes.login) {
    await storage.clear();
  }
  return targetPath;
}

Future<String?> _routeRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final path = state.matchedLocation;
  final storage = AppContainer.instance.tokenStorage;
  final token = await storage.readAccessToken();
  final hasToken = token != null && token.trim().isNotEmpty;

  if (!hasToken) {
    return RouteGuard.isPublicRoute(path) ? null : AppRoutes.login;
  }

  final trimmedToken = token!.trim();

  if (_isTokenExpired(trimmedToken)) {
    await storage.clear();
    return path == AppRoutes.onboarding
        ? AppRoutes.onboarding
        : AppRoutes.login;
  }

  final role = _extractRoleFromToken(trimmedToken);
  final targetPath = _targetPathForRole(role);

  if (targetPath == AppRoutes.login) {
    await storage.clear();
    return AppRoutes.login;
  }

  if (RouteGuard.isPublicRoute(path)) {
    return targetPath;
  }

  if (!RouteGuard.isRouteAllowedForRole(path, role)) {
    return targetPath;
  }

  return null;
}

/// ROUTER
GoRouter buildRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  redirect: _routeRedirect,
  routes: [
    /// ======================
    /// 🌍 GLOBAL ROUTES
    /// ======================
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.root, builder: (_, __) => const LoginScreen()),

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
class ThemeController extends ChangeNotifier {
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );
  final ValueNotifier<Color> brandColor = ValueNotifier<Color>(
    OpenVtsTheme.defaultBrand,
  );
  final ValueNotifier<TextDirection> textDirection =
      ValueNotifier<TextDirection>(TextDirection.ltr);
  final ValueNotifier<String> units = ValueNotifier<String>('KM');

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool("isDark") ?? false;
    final modeRaw = prefs.getString("themeMode");
    final colorValue =
        prefs.getInt("brandColor") ?? OpenVtsTheme.defaultBrand.toARGB32();
    final directionRaw =
        prefs.getString("layoutDirection") ?? prefs.getString("direction");
    final unitsRaw = prefs.getString("units") ?? 'KM';

    themeMode.value = switch (modeRaw) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => isDark ? ThemeMode.dark : ThemeMode.light,
    };
    var nextBrand = Color(colorValue);
    final bool isLightMode =
        themeMode.value != ThemeMode.dark && isDark == false;
    if (isLightMode &&
        ThemeData.estimateBrightnessForColor(nextBrand) == Brightness.light) {
      nextBrand = OpenVtsTheme.defaultBrand;
      await prefs.setInt("brandColor", nextBrand.toARGB32());
    }
    brandColor.value = nextBrand;
    textDirection.value = (directionRaw ?? '').trim().toUpperCase() == 'RTL'
        ? TextDirection.rtl
        : TextDirection.ltr;
    units.value = _normalizeUnits(unitsRaw);

    notifyListeners();
  }

  String _normalizeUnits(String value) {
    final v = value.trim().toUpperCase();
    if (v == 'MILES' || v == 'MILE' || v == 'MI') return 'MILES';
    return 'KM';
  }

  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;

    // Keep default brand contrast usable immediately when toggling modes.
    if (mode == ThemeMode.dark &&
        brandColor.value == OpenVtsTheme.defaultBrand) {
      brandColor.value = OpenVtsTheme.defaultDarkBrand;
    } else if (mode == ThemeMode.light &&
        brandColor.value == OpenVtsTheme.defaultDarkBrand) {
      brandColor.value = OpenVtsTheme.defaultBrand;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "themeMode",
      mode == ThemeMode.system
          ? "system"
          : (mode == ThemeMode.dark ? "dark" : "light"),
    );
    await prefs.setBool("isDark", mode == ThemeMode.dark);
    await prefs.setInt("brandColor", brandColor.value.toARGB32());
  }

  Future<void> setBrand(Color color) async {
    brandColor.value = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("brandColor", color.toARGB32());
  }

  Future<void> setTextDirection(String direction) async {
    final normalized = direction.trim().toUpperCase() == 'RTL' ? 'RTL' : 'LTR';
    textDirection.value = normalized == 'RTL'
        ? TextDirection.rtl
        : TextDirection.ltr;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("layoutDirection", normalized);
    await prefs.setString("direction", normalized);
  }

  Future<void> setUnits(String value) async {
    final normalized = _normalizeUnits(value);
    units.value = normalized;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("units", normalized);
  }
}

final themeController = ThemeController();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
  if (kDebugMode) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.debug('FLUTTER_ERROR: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.debug('PLATFORM_ERROR: $error');
      debugPrintStack(stackTrace: stack);
      return false;
    };
  }
  await ApiBaseUrlConfig.instance.load();
  AppContainer.initialize();
  await themeController.loadTheme();
  final initialLocation = await _resolveInitialLocation();
  const forceDevicePreview = bool.fromEnvironment(
    'DEVICE_PREVIEW',
    defaultValue: false,
  );
  final enableDevicePreview = forceDevicePreview && !kReleaseMode;
  if (kDebugMode) {
    AppLogger.debug('[AuthBootstrap] initialLocation=$initialLocation');
    AppLogger.debug('[Bootstrap] devicePreview=$enableDevicePreview');
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

class MyApp extends StatefulWidget {
  final GoRouter router;
  final bool enableDevicePreview;

  const MyApp({
    super.key,
    required this.router,
    this.enableDevicePreview = false,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<void>? _sessionExpiredSub;
  DateTime? _lastSessionNoticeAt;

  @override
  void initState() {
    super.initState();
    _sessionExpiredSub = SessionExpiredBus.stream.listen((_) async {
      await AppContainer.instance.tokenStorage.clear();
      if (!mounted) return;
      widget.router.go(AppRoutes.login);
      final now = DateTime.now();
      final last = _lastSessionNoticeAt;
      if (last == null || now.difference(last).inSeconds >= 2) {
        _lastSessionNoticeAt = now;
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, child) {
        return AnimatedBuilder(
          animation: themeController,
          builder: (_, __) {
            final mode = themeController.themeMode.value;
            final brand = themeController.brandColor.value;
            final direction = themeController.textDirection.value;

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              locale: widget.enableDevicePreview
                  ? DevicePreview.locale(context)
                  : null,
              builder: (context, child) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final backgroundColor = theme.scaffoldBackgroundColor;
                final overlayStyle = SystemUiOverlayStyle(
                  statusBarColor: backgroundColor,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDark
                      ? Brightness.dark
                      : Brightness.light,
                  systemNavigationBarColor: backgroundColor,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarDividerColor: Colors.transparent,
                );

                Widget result = AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: ColoredBox(
                    color: backgroundColor,
                    child: Directionality(
                      textDirection: direction,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
                if (widget.enableDevicePreview) {
                  result = DevicePreview.appBuilder(context, result);
                }
                if (kDebugMode) {
                  result = Banner(
                    message: 'WEB DEBUG',
                    location: BannerLocation.topStart,
                    child: result,
                  );
                }
                return result;
              },
              routerConfig: widget.router,
              theme: OpenVtsTheme.light(brand),
              darkTheme: OpenVtsTheme.dark(brand),
              themeMode: mode,
            );
          },
        );
      },
    );
  }
}
