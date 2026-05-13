import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/router/guards/route_guard.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';

/// High-level auth guard facade for router code that works with typed roles.
class AuthGuard {
  const AuthGuard._();

  static bool isPublicRoute(String path) => RouteGuard.isPublicRoute(path);

  static String defaultRouteForRole(UserRole role) => switch (role) {
        UserRole.superadmin => AppRoutePaths.superadminHome,
        UserRole.admin => AppRoutePaths.adminHome,
        UserRole.user || UserRole.subuser || UserRole.team => AppRoutePaths.userHome,
        UserRole.driver => AppRoutePaths.userHome,
        UserRole.unknown => AppRoutePaths.login,
      };
}
