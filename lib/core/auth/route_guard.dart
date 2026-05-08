import 'package:open_vts/core/repositories/auth_repository.dart';
import 'package:open_vts/app/router/app_route_paths.dart';

class RouteGuard {
  static const Set<String> _publicRoutes = {
    AppRoutePaths.root,
    AppRoutePaths.login,
    AppRoutePaths.onboarding,
  };

  static bool isPublicRoute(String path) => _publicRoutes.contains(path);

  /// Extracts the role from a JWT token.
  static String? roleForToken(String token) {
    return AuthRepository.extractRole(null, token: token);
  }

  static String normalizeRole(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    if (normalized.contains('super')) return 'superadmin';
    if (normalized.contains('admin')) return 'admin';
    if (normalized.contains('user')) return 'user';
    if (normalized.contains('driver')) return 'driver';
    return '';
  }

  /// Returns the default route for a given role.
  static String defaultRouteForRole(String? role) {
    switch (normalizeRole(role)) {
      case 'superadmin':
        return AppRoutePaths.superadminHome;
      case 'admin':
        return AppRoutePaths.adminHome;
      case 'user':
      case 'driver':
        return AppRoutePaths.userHome;
      default:
        return AppRoutePaths.login;
    }
  }

  /// Checks if a route is allowed for a given role.
  static bool isRouteAllowedForRole(String path, String? role) {
    if (isPublicRoute(path)) {
      return true;
    }

    final normalizedRole = normalizeRole(role);

    if (normalizedRole == 'superadmin') return true;

    if (normalizedRole == 'admin') {
      // Admins cannot access superadmin routes unless impersonation is added.
      return !path.startsWith(AppRoutePaths.superadmin);
    }

    if (normalizedRole == 'user' || normalizedRole == 'driver') {
      return !path.startsWith(AppRoutePaths.admin) && !path.startsWith(AppRoutePaths.superadmin);
    }

    return false;
  }
}