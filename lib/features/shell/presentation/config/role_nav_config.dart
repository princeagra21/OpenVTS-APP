import 'package:flutter/cupertino.dart';
import 'package:open_vts/core/router/route_names.dart';

enum OpenVtsRole { superadmin, admin, user, driver }

class OpenVtsBottomNavItem {
  const OpenVtsBottomNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class OpenVtsMoreMenuItem {
  const OpenVtsMoreMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class OpenVtsRoleAction {
  const OpenVtsRoleAction({
    required this.id,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool destructive;
}

class OpenVtsRoleNavConfig {
  const OpenVtsRoleNavConfig({
    required this.role,
    required this.roleLabel,
    required this.homeRoute,
    required this.allowedRoutePrefixes,
    required this.bottomNavItems,
    required this.moreMenuItems,
    required this.hiddenBottomNavPrefixes,
    required this.notificationsRoute,
    this.roleActions = const <OpenVtsRoleAction>[],
    this.showBottomNavByDefault = true,
    this.useHomeStyleAppBar = false,
  });

  final OpenVtsRole role;
  final String roleLabel;
  final String homeRoute;
  final List<String> allowedRoutePrefixes;
  final List<OpenVtsBottomNavItem> bottomNavItems;
  final List<OpenVtsMoreMenuItem> moreMenuItems;
  final List<String> hiddenBottomNavPrefixes;
  final String notificationsRoute;
  final List<OpenVtsRoleAction> roleActions;
  final bool showBottomNavByDefault;
  final bool useHomeStyleAppBar;

  bool allowsRoute(String path) {
    for (final prefix in allowedRoutePrefixes) {
      if (path.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  bool isBottomNavHiddenForPath(String path) {
    for (final prefix in hiddenBottomNavPrefixes) {
      if (path.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  int? selectedBottomNavIndex(String currentPath) {
    for (int index = 0; index < bottomNavItems.length; index++) {
      if (currentPath.startsWith(bottomNavItems[index].route)) {
        return index;
      }
    }
    return null;
  }
}

class OpenVtsRoleNavConfigs {
  const OpenVtsRoleNavConfigs._();

  static OpenVtsRoleNavConfig of(OpenVtsRole role) {
    return _configs[role] ?? _configs[OpenVtsRole.user]!;
  }

  static final Map<OpenVtsRole, OpenVtsRoleNavConfig> _configs =
      <OpenVtsRole, OpenVtsRoleNavConfig>{
        OpenVtsRole.admin: OpenVtsRoleNavConfig(
          role: OpenVtsRole.admin,
          roleLabel: 'Admin',
          homeRoute: AppRoutePaths.adminHome,
          allowedRoutePrefixes: const <String>[AppRoutePaths.admin],
          bottomNavItems: const <OpenVtsBottomNavItem>[
            OpenVtsBottomNavItem(
              label: 'Dashboard',
              icon: CupertinoIcons.house_fill,
              route: AppRoutePaths.adminHome,
            ),
            OpenVtsBottomNavItem(
              label: 'Map',
              icon: CupertinoIcons.map_fill,
              route: AppRoutePaths.adminMap,
            ),
            OpenVtsBottomNavItem(
              label: 'Settings',
              icon: CupertinoIcons.settings,
              route: AppRoutePaths.adminSettings,
            ),
            OpenVtsBottomNavItem(
              label: 'More',
              icon: CupertinoIcons.ellipsis_circle_fill,
              route: AppRoutePaths.adminMore,
            ),
          ],
          moreMenuItems: const <OpenVtsMoreMenuItem>[
            OpenVtsMoreMenuItem(
              title: 'User',
              subtitle: 'Manage users',
              icon: CupertinoIcons.person,
              route: AppRoutePaths.adminUsers,
            ),
            OpenVtsMoreMenuItem(
              title: 'Vehicle',
              subtitle: 'Fleet vehicles',
              icon: CupertinoIcons.bus,
              route: AppRoutePaths.adminVehicles,
            ),
            OpenVtsMoreMenuItem(
              title: 'Drivers',
              subtitle: 'Driver profiles',
              icon: CupertinoIcons.person_crop_square,
              route: AppRoutePaths.adminDrivers,
            ),
            OpenVtsMoreMenuItem(
              title: 'Devices',
              subtitle: 'Tracking hardware',
              icon: CupertinoIcons.device_phone_portrait,
              route: AppRoutePaths.adminDevices,
            ),
            OpenVtsMoreMenuItem(
              title: 'Sim Card',
              subtitle: 'Network connectivity',
              icon: CupertinoIcons.creditcard,
              route: AppRoutePaths.adminSims,
            ),
            OpenVtsMoreMenuItem(
              title: 'Transaction History',
              subtitle: 'All transactions',
              icon: CupertinoIcons.doc_text,
              route: AppRoutePaths.adminTransactions,
            ),
            OpenVtsMoreMenuItem(
              title: 'Support',
              subtitle: 'Help center',
              icon: CupertinoIcons.question_circle,
              route: AppRoutePaths.adminSupport,
            ),
            OpenVtsMoreMenuItem(
              title: 'Calendar',
              subtitle: 'Schedules',
              icon: CupertinoIcons.calendar,
              route: AppRoutePaths.adminCalendar,
            ),
            OpenVtsMoreMenuItem(
              title: 'Logs',
              subtitle: 'System activity',
              icon: CupertinoIcons.list_bullet,
              route: AppRoutePaths.adminLogs,
            ),
          ],
          hiddenBottomNavPrefixes: const <String>[
            AppRoutePaths.adminsDetailsLegacyPrefix,
            AppRoutePaths.adminVehiclesDetailsPrefix,
            AppRoutePaths.adminDriversDetailsPrefix,
            AppRoutePaths.adminProfile,
            AppRoutePaths.adminWhiteLabel,
            AppRoutePaths.adminBranding,
            AppRoutePaths.adminApiConfig,
            AppRoutePaths.adminLocalization,
            AppRoutePaths.adminApplicationSettings,
            AppRoutePaths.adminNotificationSettings,
            AppRoutePaths.adminEmailSettings,
            AppRoutePaths.adminSmtpSettings,
            AppRoutePaths.adminUserPolicy,
            AppRoutePaths.adminPaymentGateway,
            AppRoutePaths.adminServer,
            AppRoutePaths.adminCalendar,
            AppRoutePaths.adminRoles,
            AppRoutePaths.adminSsl,
            AppRoutePaths.adminAllTransactions,
            AppRoutePaths.adminAllActivities,
          ],
          notificationsRoute: AppRoutePaths.adminNotifications,
          roleActions: const <OpenVtsRoleAction>[
            OpenVtsRoleAction(
              id: 'logout',
              label: 'Log out',
              icon: CupertinoIcons.square_arrow_right,
              destructive: true,
            ),
          ],
          showBottomNavByDefault: true,
          useHomeStyleAppBar: false,
        ),
        OpenVtsRole.superadmin: OpenVtsRoleNavConfig(
          role: OpenVtsRole.superadmin,
          roleLabel: 'Superadmin',
          homeRoute: AppRoutePaths.superadminHome,
          allowedRoutePrefixes: const <String>[AppRoutePaths.superadmin],
          bottomNavItems: const <OpenVtsBottomNavItem>[
            OpenVtsBottomNavItem(
              label: 'Home',
              icon: CupertinoIcons.house_fill,
              route: AppRoutePaths.superadminHome,
            ),
            OpenVtsBottomNavItem(
              label: 'Map',
              icon: CupertinoIcons.map_fill,
              route: AppRoutePaths.superadminMap,
            ),
            OpenVtsBottomNavItem(
              label: 'Admins',
              icon: CupertinoIcons.person_2_fill,
              route: AppRoutePaths.superadminAdmins,
            ),
            OpenVtsBottomNavItem(
              label: 'Vehicles',
              icon: CupertinoIcons.car_detailed,
              route: AppRoutePaths.superadminVehicles,
            ),
            OpenVtsBottomNavItem(
              label: 'More',
              icon: CupertinoIcons.ellipsis_circle_fill,
              route: AppRoutePaths.superadminMore,
            ),
          ],
          moreMenuItems: const <OpenVtsMoreMenuItem>[
            OpenVtsMoreMenuItem(
              title: 'Calendar',
              subtitle: 'Jobs and events',
              icon: CupertinoIcons.calendar,
              route: AppRoutePaths.superadminCalendar,
            ),
            OpenVtsMoreMenuItem(
              title: 'Support',
              subtitle: 'Help center',
              icon: CupertinoIcons.question_circle,
              route: AppRoutePaths.superadminSupport,
            ),
            OpenVtsMoreMenuItem(
              title: 'Setting',
              subtitle: 'App and account',
              icon: CupertinoIcons.settings_solid,
              route: AppRoutePaths.superadminSettings,
            ),
            OpenVtsMoreMenuItem(
              title: 'Roles',
              subtitle: 'Admin and permissions',
              icon: CupertinoIcons.person_2_fill,
              route: AppRoutePaths.superadminRoles,
            ),
          ],
          hiddenBottomNavPrefixes: const <String>[
            AppRoutePaths.superadminAdminsDetailsPrefix,
            AppRoutePaths.superadminVehiclesDetailsPrefix,
            AppRoutePaths.superadminProfile,
            AppRoutePaths.superadminSettings,
            AppRoutePaths.superadminWhiteLabel,
            AppRoutePaths.superadminBranding,
            AppRoutePaths.superadminApiConfig,
            AppRoutePaths.superadminLocalization,
            AppRoutePaths.superadminApplicationSettings,
            AppRoutePaths.superadminNotificationSettings,
            AppRoutePaths.superadminEmailSettings,
            AppRoutePaths.superadminSmtpSettings,
            AppRoutePaths.superadminPaymentGateway,
            AppRoutePaths.superadminServer,
            AppRoutePaths.superadminSsl,
            AppRoutePaths.superadminRoles,
            AppRoutePaths.superadminAllTransactions,
            AppRoutePaths.superadminAllActivities,
          ],
          notificationsRoute: AppRoutePaths.superadminNotifications,
          roleActions: const <OpenVtsRoleAction>[
            OpenVtsRoleAction(
              id: 'logout',
              label: 'Log out',
              icon: CupertinoIcons.square_arrow_right,
              destructive: true,
            ),
          ],
          showBottomNavByDefault: false,
          useHomeStyleAppBar: false,
        ),
        OpenVtsRole.user: OpenVtsRoleNavConfig(
          role: OpenVtsRole.user,
          roleLabel: 'User',
          homeRoute: AppRoutePaths.userHome,
          allowedRoutePrefixes: const <String>[AppRoutePaths.user],
          bottomNavItems: const <OpenVtsBottomNavItem>[
            OpenVtsBottomNavItem(
              label: 'Home',
              icon: CupertinoIcons.house_fill,
              route: AppRoutePaths.userHome,
            ),
            OpenVtsBottomNavItem(
              label: 'Maps',
              icon: CupertinoIcons.map_fill,
              route: AppRoutePaths.userMaps,
            ),
            OpenVtsBottomNavItem(
              label: 'Geofence',
              icon: CupertinoIcons.map_pin_ellipse,
              route: AppRoutePaths.userGeofence,
            ),
            OpenVtsBottomNavItem(
              label: 'Tools',
              icon: CupertinoIcons.person_2_fill,
              route: AppRoutePaths.userAdmin,
            ),
            OpenVtsBottomNavItem(
              label: 'More',
              icon: CupertinoIcons.ellipsis_circle_fill,
              route: AppRoutePaths.userMore,
            ),
          ],
          moreMenuItems: const <OpenVtsMoreMenuItem>[
            OpenVtsMoreMenuItem(
              title: 'Profile',
              subtitle: 'View and edit your profile',
              icon: CupertinoIcons.person,
              route: AppRoutePaths.userProfile,
            ),
            OpenVtsMoreMenuItem(
              title: 'Notifications',
              subtitle: 'Manage alerts and pushes',
              icon: CupertinoIcons.bell,
              route: AppRoutePaths.userNotificationSettings,
            ),
            OpenVtsMoreMenuItem(
              title: 'Localization',
              subtitle: 'Language and regional settings',
              icon: CupertinoIcons.globe,
              route: AppRoutePaths.userLocalization,
            ),
          ],
          hiddenBottomNavPrefixes: const <String>[
            AppRoutePaths.usersDetailsLegacyPrefix,
            AppRoutePaths.userDriversDetailsPrefix,
            AppRoutePaths.userVehiclesDetailsPrefix,
            AppRoutePaths.userProfile,
            AppRoutePaths.userWhiteLabel,
            AppRoutePaths.userBranding,
            AppRoutePaths.userApiConfig,
            AppRoutePaths.userLocalization,
            AppRoutePaths.userApplicationSettings,
            AppRoutePaths.userNotificationSettings,
            AppRoutePaths.userEmailSettings,
            AppRoutePaths.userSmtpSettings,
            AppRoutePaths.userUserPolicy,
            AppRoutePaths.userPaymentGateway,
            AppRoutePaths.userServer,
            AppRoutePaths.userCalendar,
            AppRoutePaths.userRoles,
            AppRoutePaths.userSsl,
            AppRoutePaths.userAllTransactions,
            AppRoutePaths.userAllActivities,
          ],
          notificationsRoute: AppRoutePaths.userNotifications,
          roleActions: const <OpenVtsRoleAction>[
            OpenVtsRoleAction(
              id: 'logout',
              label: 'Log out',
              icon: CupertinoIcons.square_arrow_right,
              destructive: true,
            ),
          ],
          showBottomNavByDefault: false,
          useHomeStyleAppBar: true,
        ),
        OpenVtsRole.driver: OpenVtsRoleNavConfig(
          role: OpenVtsRole.driver,
          roleLabel: 'Driver',
          homeRoute: AppRoutePaths.driverHome,
          allowedRoutePrefixes: const <String>[AppRoutePaths.driver],
          bottomNavItems: const <OpenVtsBottomNavItem>[
            OpenVtsBottomNavItem(
              label: 'Home',
              icon: CupertinoIcons.house_fill,
              route: AppRoutePaths.driverHome,
            ),
            OpenVtsBottomNavItem(
              label: 'Map',
              icon: CupertinoIcons.map_fill,
              route: AppRoutePaths.driverMap,
            ),
            OpenVtsBottomNavItem(
              label: 'More',
              icon: CupertinoIcons.ellipsis_circle_fill,
              route: AppRoutePaths.driverMore,
            ),
          ],
          moreMenuItems: const <OpenVtsMoreMenuItem>[
            OpenVtsMoreMenuItem(
              title: 'Profile',
              subtitle: 'View your profile',
              icon: CupertinoIcons.person,
              route: AppRoutePaths.driverProfile,
            ),
          ],
          hiddenBottomNavPrefixes: const <String>[],
          notificationsRoute: AppRoutePaths.driverNotifications,
          roleActions: const <OpenVtsRoleAction>[
            OpenVtsRoleAction(
              id: 'logout',
              label: 'Log out',
              icon: CupertinoIcons.square_arrow_right,
              destructive: true,
            ),
          ],
          showBottomNavByDefault: false,
          useHomeStyleAppBar: true,
        ),
      };
}
