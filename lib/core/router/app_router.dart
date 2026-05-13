import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/router/guards/route_guard.dart';
import 'package:open_vts/features/auth/presentation/screens/login_screen.dart';
import 'package:open_vts/features/admin/admin.dart';
import 'package:open_vts/features/superadmin/superadmin.dart';
import 'package:open_vts/features/user/user.dart';
import 'package:open_vts/features/auth/presentation/screens/onboarding_screen.dart';

/// Central GoRouter factory for the enterprise architecture.
///
/// It keeps all existing role routes alive while moving router ownership out of
/// `main.dart` for new work.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  /// Resolves the first route before building the app router.
  ///
  /// Keeping this here removes JWT/role routing logic from `main.dart` and
  /// makes navigation ownership match the enterprise architecture blueprint.
  static Future<String> resolveInitialLocation({
    required TokenStorageBase tokenStorage,
  }) async {
    final storage = tokenStorage;
    final token = await storage.readAccessToken();

    if (token == null || token.trim().isEmpty) {
      return AppRoutePaths.onboarding;
    }

    final trimmedToken = token.trim();
    if (_isTokenExpired(trimmedToken)) {
      await storage.clear();
      return AppRoutePaths.onboarding;
    }

    final role = _extractRoleFromToken(trimmedToken);
    final targetPath = RouteGuard.defaultRouteForRole(role);
    if (targetPath == AppRoutePaths.login) {
      await storage.clear();
    }
    return targetPath;
  }

  static GoRouter build({
    required String initialLocation,
    required TokenStorageBase tokenStorage,
  }) => GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: initialLocation,
        redirect: (context, state) => redirect(
          context,
          state,
          tokenStorage: tokenStorage,
        ),
        routes: [
          GoRoute(
            path: AppRoutePaths.onboarding,
            builder: (_, __) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.login,
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.root,
            builder: (_, __) => const LoginScreen(),
          ),
          ...superAdminRoutes,
          ...adminRoutes,
          ...userRoutes,
        ],
      );

  static FutureOr<String?> redirect(
    BuildContext context,
    GoRouterState state, {
    required TokenStorageBase tokenStorage,
  }) async {
    final path = state.matchedLocation;
    final storage = tokenStorage;
    final token = await storage.readAccessToken();
    final hasToken = token != null && token.trim().isNotEmpty;

    if (!hasToken) {
      return RouteGuard.isPublicRoute(path) ? null : AppRoutePaths.login;
    }

    final trimmedToken = token.trim();
    if (_isTokenExpired(trimmedToken)) {
      await storage.clear();
      return path == AppRoutePaths.onboarding
          ? AppRoutePaths.onboarding
          : AppRoutePaths.login;
    }

    final role = _extractRoleFromToken(trimmedToken);
    final targetPath = RouteGuard.defaultRouteForRole(role);

    if (targetPath == AppRoutePaths.login) {
      await storage.clear();
      return AppRoutePaths.login;
    }

    if (RouteGuard.isPublicRoute(path)) return targetPath;
    if (!RouteGuard.isRouteAllowedForRole(path, role)) return targetPath;
    return null;
  }

  static bool _isTokenExpired(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return false;
    final expRaw = payload['exp'];
    final expSeconds = switch (expRaw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (expSeconds == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiry);
  }

  static String? _extractRoleFromToken(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return null;

    String? pick(Object? value) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is List) {
        for (final item in value) {
          final resolved = pick(item);
          if (resolved != null) return resolved;
        }
      }
      if (value is Map) {
        return pick(value['name'] ?? value['role'] ?? value['type'] ?? value['slug'] ?? value['code']);
      }
      final s = value.toString().trim();
      return s.isEmpty ? null : s;
    }

    String? pickFromMap(Map map) {
      for (final v in [map['role'], map['userRole'], map['userType'], map['roleType'], map['type']]) {
        final role = pick(v);
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

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded.cast());
    } catch (_) {
      return null;
    }
    return null;
  }
}
