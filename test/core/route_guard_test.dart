import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/app/router/app_route_paths.dart';
import 'package:open_vts/core/auth/route_guard.dart';

void main() {
  group('RouteGuard', () {
    group('isPublicRoute', () {
      test('returns true for public routes', () {
        expect(RouteGuard.isPublicRoute(AppRoutePaths.root), isTrue);
        expect(RouteGuard.isPublicRoute(AppRoutePaths.login), isTrue);
        expect(RouteGuard.isPublicRoute(AppRoutePaths.onboarding), isTrue);
      });

      test('returns false for protected routes', () {
        expect(RouteGuard.isPublicRoute(AppRoutePaths.adminHome), isFalse);
        expect(RouteGuard.isPublicRoute(AppRoutePaths.superadminHome), isFalse);
        expect(RouteGuard.isPublicRoute(AppRoutePaths.userHome), isFalse);
      });
    });

    group('normalizeRole', () {
      test('normalizes superadmin variants', () {
        expect(RouteGuard.normalizeRole('superadmin'), 'superadmin');
        expect(RouteGuard.normalizeRole('Super Admin'), 'superadmin');
        expect(RouteGuard.normalizeRole('SUPERADMIN'), 'superadmin');
      });

      test('normalizes admin variants', () {
        expect(RouteGuard.normalizeRole('admin'), 'admin');
        expect(RouteGuard.normalizeRole('Admin'), 'admin');
        expect(RouteGuard.normalizeRole('ADMIN'), 'admin');
      });

      test('normalizes user variants', () {
        expect(RouteGuard.normalizeRole('user'), 'user');
        expect(RouteGuard.normalizeRole('User'), 'user');
        expect(RouteGuard.normalizeRole('USER'), 'user');
      });

      test('normalizes driver variants', () {
        expect(RouteGuard.normalizeRole('driver'), 'driver');
        expect(RouteGuard.normalizeRole('Driver'), 'driver');
      });

      test('returns empty for unknown roles', () {
        expect(RouteGuard.normalizeRole('unknown'), '');
        expect(RouteGuard.normalizeRole(null), '');
        expect(RouteGuard.normalizeRole(''), '');
      });
    });

    group('defaultRouteForRole', () {
      test('returns superadmin home for superadmin', () {
        expect(RouteGuard.defaultRouteForRole('superadmin'), AppRoutePaths.superadminHome);
        expect(RouteGuard.defaultRouteForRole('Super Admin'), AppRoutePaths.superadminHome);
      });

      test('returns admin home for admin', () {
        expect(RouteGuard.defaultRouteForRole('admin'), AppRoutePaths.adminHome);
        expect(RouteGuard.defaultRouteForRole('Admin'), AppRoutePaths.adminHome);
      });

      test('returns user home for user/driver', () {
        expect(RouteGuard.defaultRouteForRole('user'), AppRoutePaths.userHome);
        expect(RouteGuard.defaultRouteForRole('driver'), AppRoutePaths.userHome);
        expect(RouteGuard.defaultRouteForRole('User'), AppRoutePaths.userHome);
      });

      test('returns login for unknown roles', () {
        expect(RouteGuard.defaultRouteForRole('unknown'), AppRoutePaths.login);
        expect(RouteGuard.defaultRouteForRole(null), AppRoutePaths.login);
        expect(RouteGuard.defaultRouteForRole(''), AppRoutePaths.login);
      });
    });

    group('isRouteAllowedForRole', () {
      test('allows public routes for all roles', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.root, 'superadmin'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.login, 'admin'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.onboarding, 'user'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.root, null), isTrue);
      });

      test('superadmin can access all routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.superadminHome, 'superadmin'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.adminHome, 'superadmin'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.userHome, 'superadmin'), isTrue);
      });

      test('admin cannot access superadmin routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.superadminHome, 'admin'), isFalse);
        expect(RouteGuard.isRouteAllowedForRole('/superadmin/something', 'admin'), isFalse);
      });

      test('admin can access admin and user routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.adminHome, 'admin'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.userHome, 'admin'), isTrue);
      });

      test('user cannot access admin or superadmin routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.adminHome, 'user'), isFalse);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.superadminHome, 'user'), isFalse);
        expect(RouteGuard.isRouteAllowedForRole('/admin/something', 'user'), isFalse);
        expect(RouteGuard.isRouteAllowedForRole('/superadmin/something', 'user'), isFalse);
      });

      test('user can access user routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.userHome, 'user'), isTrue);
      });

      test('driver has same permissions as user', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.userHome, 'driver'), isTrue);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.adminHome, 'driver'), isFalse);
      });

      test('unknown roles cannot access protected routes', () {
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.adminHome, 'unknown'), isFalse);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.userHome, null), isFalse);
        expect(RouteGuard.isRouteAllowedForRole(AppRoutePaths.superadminHome, ''), isFalse);
      });
    });
  });
}