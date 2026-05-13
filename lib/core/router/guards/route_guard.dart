import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';

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
    final resolved = UserRole.fromBackend(role);
    return resolved == UserRole.unknown ? '' : resolved.backendValue.toLowerCase();
  }

  static UserRole roleEnum(String? role) => UserRole.fromBackend(role);

  /// Returns the default route for a given role.
  static String defaultRouteForRole(String? role) {
    switch (roleEnum(role)) {
      case UserRole.superadmin:
        return AppRoutePaths.superadminHome;
      case UserRole.admin:
        return AppRoutePaths.adminHome;
      case UserRole.user:
      case UserRole.subuser:
      case UserRole.team:
      case UserRole.driver:
        return AppRoutePaths.userHome;
      case UserRole.unknown:
        return AppRoutePaths.login;
    }
  }

  /// Checks if a route is allowed for a given role.
  static bool isRouteAllowedForRole(String path, String? role) {
    if (isPublicRoute(path)) {
      return true;
    }

    final resolvedRole = roleEnum(role);

    if (resolvedRole == UserRole.superadmin) return true;

    if (resolvedRole == UserRole.admin) {
      // Admins cannot access superadmin routes unless impersonation is added.
      return !path.startsWith(AppRoutePaths.superadmin);
    }

    if (resolvedRole == UserRole.user ||
        resolvedRole == UserRole.subuser ||
        resolvedRole == UserRole.team ||
        resolvedRole == UserRole.driver) {
      return !path.startsWith(AppRoutePaths.admin) &&
          !path.startsWith(AppRoutePaths.superadmin);
    }

    return false;
  }
}