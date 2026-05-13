import 'package:open_vts/features/user/presentation/screens/report/generate_report.dart';
import 'package:open_vts/features/user/presentation/screens/route/route_optimazation.dart';
import 'package:open_vts/features/user/presentation/screens/admin/admin.dart';
import 'package:open_vts/features/user/presentation/screens/admin/screens/add_share_track.dart';
import 'package:open_vts/features/user/presentation/screens/admin/screens/share_track_link.dart';
import 'package:open_vts/features/user/presentation/screens/account/accounts_screen.dart';
import 'package:open_vts/features/user/presentation/screens/drivers/add_driver_screen.dart';
import 'package:open_vts/features/user/presentation/screens/drivers/driver_details_screen.dart';
import 'package:open_vts/features/user/presentation/screens/drivers/edit_driver_profile_screen.dart';
import 'package:open_vts/features/user/presentation/screens/drivers/driver_screen.dart';
import 'package:open_vts/features/user/presentation/screens/home/home_screen.dart';
import 'package:open_vts/features/user/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:open_vts/features/user/presentation/screens/landmark/geofence.dart';
import 'package:open_vts/features/user/presentation/screens/localization/localization.dart';
import 'package:open_vts/features/user/presentation/screens/map/map_screen.dart';
import 'package:open_vts/features/user/presentation/screens/more/more_screen.dart';
import 'package:open_vts/features/user/presentation/screens/notification/notification.dart';
import 'package:open_vts/features/user/presentation/screens/notification/notification_settings_screen.dart';
import 'package:open_vts/features/user/presentation/screens/notification/vehicle_toggle_screen.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification_screen.dart';
import 'package:open_vts/features/user/presentation/screens/profile/profile_screen.dart';
import 'package:open_vts/features/user/presentation/screens/sub_users/add_sub_user_screen.dart';
import 'package:open_vts/features/user/presentation/screens/sub_users/sub_user_details_screen.dart';
import 'package:open_vts/features/user/presentation/screens/sub_users/sub_user_screen.dart';
import 'package:open_vts/features/user/presentation/screens/support/support_screen.dart';
import 'package:open_vts/features/user/presentation/screens/transaction/transaction.dart';
import 'package:open_vts/features/user/presentation/screens/transaction/transaction_details.dart';
import 'package:open_vts/features/user/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:open_vts/features/user/presentation/screens/vehicles/vehicle_details_screen.dart';
import 'package:open_vts/features/user/presentation/screens/vehicles/vehicle_screen.dart';
import 'package:open_vts/features/user/presentation/screens/setting/setting_screen.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_item.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/router/route_names.dart';

final List<GoRoute> userRoutes = [
  GoRoute(path: AppRoutePaths.user, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutePaths.userHome, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutePaths.userDashboard, builder: (_, __) => const DashboardScreen()),
  GoRoute(path: AppRoutePaths.userMaps, builder: (_, __) => const MapScreen()),
  GoRoute(path: AppRoutePaths.userAdmin, builder: (_, __) => const AdminScreen()),
  GoRoute(path: AppRoutePaths.userAccounts, builder: (_, __) => const AccountsScreen()),
  GoRoute(
    path: AppRoutePaths.userShareTrack,
    builder: (_, __) => const ShareTrackScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userShareTrackAdd,
    builder: (_, __) => const ShareTrackAddScreen(),
  ),
  GoRoute(path: AppRoutePaths.userVehicles, builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: AppRoutePaths.userVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userVehiclesDetailsPattern,
    builder: (context, state) => VehicleDetailsScreen(
      vehicleId: state.pathParameters['id']!,
      initialVehicle: state.extra is VehicleListItem
          ? state.extra as VehicleListItem
          : null,
    ),
  ),
  GoRoute(path: AppRoutePaths.userDrivers, builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: AppRoutePaths.userDriversAdd,
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userDriversDetailsPattern,
    builder: (context, state) => DriverDetailsScreen(
      driverId: state.pathParameters['id']!,
      initialDriver: state.extra is AdminDriverListItem
          ? state.extra as AdminDriverListItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutePaths.userDriversEditPattern,
    builder: (context, state) => EditDriverProfileScreen(
      driverId: state.pathParameters['id']!,
      initialDetails: state.extra is UserDriverDetails
          ? state.extra as UserDriverDetails
          : null,
    ),
  ),
  GoRoute(path: AppRoutePaths.userGeofence, builder: (_, __) => const GeofenceScreen()),
  GoRoute(
    path: AppRoutePaths.userRouteOptimization,
    builder: (_, __) => const RouteOptimizationScreen(),
  ),
  GoRoute(path: AppRoutePaths.userSupport, builder: (_, __) => const SupportScreen()),
  GoRoute(path: AppRoutePaths.userSettings, builder: (_, __) => const SettingsScreen()),
  GoRoute(path: AppRoutePaths.userProfile, builder: (_, __) => const ProfileScreen()),
  GoRoute(
    path: AppRoutePaths.userGenerateReport,
    builder: (_, __) => const GenerateReportScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userNotificationsPush,
    builder: (_, __) => const PushNotificationScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userNotifications,
    builder: (_, __) => const NotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userNotificationSettings,
    builder: (_, __) => const NotificationSettingsScreen(),
  ),
  GoRoute(path: AppRoutePaths.userSubUsers, builder: (_, __) => const SubUserScreen()),
  GoRoute(
    path: AppRoutePaths.userSubUsersDetailsPattern,
    builder: (context, state) => SubUserDetailsScreen(
      userId: state.pathParameters['id']!,
      initialSubUser: state.extra is UserSubUserItem
          ? state.extra as UserSubUserItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutePaths.userSubUsersEditPattern,
    builder: (context, state) => AddSubUserScreen(
      subUserId: state.pathParameters['id']!,
      initialSubUser: state.extra is UserSubUserItem
          ? state.extra as UserSubUserItem
          : null,
    ),
  ),
  GoRoute(
    path: AppRoutePaths.userSubUsersAdd,
    builder: (_, __) => const AddSubUserScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userToggleEventTypePattern,
    builder: (context, state) =>
        VehicleToggleScreen(eventType: state.pathParameters['eventType']!),
  ),
  GoRoute(path: AppRoutePaths.userMore, builder: (_, __) => const MoreScreen()),
  GoRoute(
    path: AppRoutePaths.userTransactions,
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.userTransactionsDetailsPattern,
    builder: (context, state) => TransactionDetailsScreen(
      transactionId: state.pathParameters['id']!,
      transaction: state.extra is AdminTransactionItem
          ? state.extra as AdminTransactionItem
          : null,
    ),
  ),
];
