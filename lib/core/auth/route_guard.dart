import 'package:fleet_stack/core/repositories/auth_repository.dart';

class RouteGuard {
  /// Determines if a route is public (does not require authentication).
  static bool isPublicRoute(String path) {
    // Public routes that don't require authentication
    final publicRoutes = [
      '/auth/login',
      '/auth/forgot-password',
      '/auth/register', // if exists
      // Add other public routes as needed
    ];

    return publicRoutes.any((route) => path.startsWith(route)) ||
           path == '/' ||
           path.startsWith('/public');
  }

  /// Extracts the role from a JWT token.
  static String? roleForToken(String token) {
    return AuthRepository.extractRole(null, token: token);
  }

  /// Returns the default route for a given role.
  static String defaultRouteForRole(String? role) {
    if (role == null) return '/auth/login';

    switch (role.toLowerCase()) {
      case 'admin':
      case 'superadmin':
        return '/admin/dashboard';
      case 'user':
        return '/user/dashboard';
      default:
        return '/user/dashboard'; // fallback
    }
  }

  /// Checks if a route is allowed for a given role.
  static bool isRouteAllowedForRole(String path, String? role) {
    if (role == null) return isPublicRoute(path);

    final roleLower = role.toLowerCase();

    // Admin and superadmin can access everything
    if (roleLower == 'admin' || roleLower == 'superadmin') {
      return true;
    }

    // User role restrictions
    if (roleLower == 'user') {
      // Users cannot access admin routes
      if (path.startsWith('/admin') || path.startsWith('/superadmin')) {
        return false;
      }
      return true;
    }

    // Default: allow if not restricted
    return true;
  }
}