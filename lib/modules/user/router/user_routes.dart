import 'package:open_vts/modules/user/screens/report/generate_report.dart';
import 'package:open_vts/modules/user/screens/route/route_optimazation.dart';
import 'package:open_vts/modules/user/screens/admin/admin.dart';
import 'package:open_vts/modules/user/screens/admin/screens/add_share_track.dart';
import 'package:open_vts/modules/user/screens/admin/screens/share_track_link.dart';
import 'package:open_vts/modules/user/screens/account/accounts_screen.dart';
import 'package:open_vts/modules/user/screens/drivers/add_driver_screen.dart';
import 'package:open_vts/modules/user/screens/drivers/driver_details_screen.dart';
import 'package:open_vts/modules/user/screens/drivers/edit_driver_profile_screen.dart';
import 'package:open_vts/modules/user/screens/drivers/driver_screen.dart';
import 'package:open_vts/modules/user/screens/home/home_screen.dart';
import 'package:open_vts/modules/user/screens/dashboard/dashboard_screen.dart';
import 'package:open_vts/modules/user/screens/landmark/geofence.dart';
import 'package:open_vts/modules/user/screens/localization/localization.dart';
import 'package:open_vts/modules/user/screens/map/map_screen.dart';
import 'package:open_vts/modules/user/screens/more/more_screen.dart';
import 'package:open_vts/modules/user/screens/notification/notification.dart';
import 'package:open_vts/modules/user/screens/notification/notification_settings_screen.dart';
import 'package:open_vts/modules/user/screens/notification/vehicle_toggle_screen.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification_screen.dart';
import 'package:open_vts/modules/user/screens/profile/profile_screen.dart';
import 'package:open_vts/modules/user/screens/sub_users/add_sub_user_screen.dart';
import 'package:open_vts/modules/user/screens/sub_users/sub_user_details_screen.dart';
import 'package:open_vts/modules/user/screens/sub_users/sub_user_screen.dart';
import 'package:open_vts/modules/user/screens/support/support_screen.dart';
import 'package:open_vts/modules/user/screens/transaction/transaction.dart';
import 'package:open_vts/modules/user/screens/transaction/transaction_details.dart';
import 'package:open_vts/modules/user/screens/vehicles/add_vehicle_screen.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details_screen.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_screen.dart';
import 'package:open_vts/modules/user/screens/setting/setting_screen.dart';
import 'package:open_vts/core/models/admin_driver_list_item.dart';
import 'package:open_vts/core/models/admin_transaction_item.dart';
import 'package:open_vts/core/models/user_driver_details.dart';
import 'package:open_vts/core/models/user_subuser_item.dart';
import 'package:open_vts/core/models/vehicle_list_item.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/navigation/app_routes.dart';

final List<GoRoute> userRoutes = [
  GoRoute(path: AppRoutes.user, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutes.userHome, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutes.userDashboard, builder: (_, __) => const DashboardScreen()),
  GoRoute(path: AppRoutes.userMaps, builder: (_, __) => const MapScreen()),
  GoRoute(path: AppRoutes.userAdmin, builder: (_, __) => const AdminScreen()),
  GoRoute(path: AppRoutes.userAccounts, builder: (_, __) => const AccountsScreen()),
  GoRoute(
    path: AppRoutes.userShareTrack,
    builder: (_, __) => const ShareTrackScreen(),
  ),
  GoRoute(
    path: AppRoutes.userShareTrackAdd,
    builder: (_, __) => const ShareTrackAddScreen(),
  ),
  GoRoute(path: AppRoutes.userVehicles, builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: AppRoutes.userVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: AppRoutes.userVehiclesDetailsPattern,
    builder: (context, state) => VehicleDetailsScreen(
      vehicleId: state.pathParameters['id']!,
      initialVehicle: state.extra is VehicleListItem
          ? state.extra as VehicleListItem
          : null,
    ),
  ),
  GoRoute(path: AppRoutes.userDrivers, builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: AppRoutes.userDriversAdd,
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(
    path: AppRoutes.userDriversDetailsPattern,
    builder: (context, state) => DriverDetailsScreen(
      driverId: state.pathParameters['id']!,
      initialDriver: state.extra is AdminDriverListItem
          ? state.extra as AdminDriverListItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutes.userDriversEditPattern,
    builder: (context, state) => EditDriverProfileScreen(
      driverId: state.pathParameters['id']!,
      initialDetails: state.extra is UserDriverDetails
          ? state.extra as UserDriverDetails
          : null,
    ),
  ),
  GoRoute(path: AppRoutes.userGeofence, builder: (_, __) => const GeofenceScreen()),
  GoRoute(
    path: AppRoutes.userRouteOptimization,
    builder: (_, __) => const RouteOptimizationScreen(),
  ),
  GoRoute(path: AppRoutes.userSupport, builder: (_, __) => const SupportScreen()),
  GoRoute(path: AppRoutes.userSettings, builder: (_, __) => const SettingsScreen()),
  GoRoute(path: AppRoutes.userProfile, builder: (_, __) => const ProfileScreen()),
  GoRoute(
    path: AppRoutes.userGenerateReport,
    builder: (_, __) => const GenerateReportScreen(),
  ),
  GoRoute(
    path: AppRoutes.userLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.userNotificationsPush,
    builder: (_, __) => const PushNotificationScreen(),
  ),
  GoRoute(
    path: AppRoutes.userNotifications,
    builder: (_, __) => const NotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.userNotificationSettings,
    builder: (_, __) => const NotificationSettingsScreen(),
  ),
  GoRoute(path: AppRoutes.userSubUsers, builder: (_, __) => const SubUserScreen()),
  GoRoute(
    path: AppRoutes.userSubUsersDetailsPattern,
    builder: (context, state) => SubUserDetailsScreen(
      userId: state.pathParameters['id']!,
      initialSubUser: state.extra is UserSubUserItem
          ? state.extra as UserSubUserItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutes.userSubUsersEditPattern,
    builder: (context, state) => AddSubUserScreen(
      subUserId: state.pathParameters['id']!,
      initialSubUser: state.extra is UserSubUserItem
          ? state.extra as UserSubUserItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutes.userSubUsersAdd,
    builder: (_, __) => const AddSubUserScreen(),
  ),
  GoRoute(
    path: AppRoutes.userToggleEventTypePattern,
    builder: (context, state) =>
        VehicleToggleScreen(eventType: state.pathParameters['eventType']!),
  ),
  GoRoute(path: AppRoutes.userMore, builder: (_, __) => const MoreScreen()),
  GoRoute(
    path: AppRoutes.userTransactions,
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: AppRoutes.userTransactionsDetailsPattern,
    builder: (context, state) => TransactionDetailsScreen(
      transactionId: state.pathParameters['id']!,
      transaction: state.extra is AdminTransactionItem
          ? state.extra as AdminTransactionItem
          : null,
    ),
  ),
];
