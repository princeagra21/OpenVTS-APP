import 'package:fleet_stack/modules/user/screens/report/generate_report.dart';
import 'package:fleet_stack/modules/user/screens/route/route_optimazation.dart';
import 'package:fleet_stack/modules/user/screens/admin/admin.dart';
import 'package:fleet_stack/modules/user/screens/admin/screens/add_share_track.dart';
import 'package:fleet_stack/modules/user/screens/admin/screens/share_track_link.dart';
import 'package:fleet_stack/modules/user/screens/drivers/add_driver_screen.dart';
import 'package:fleet_stack/modules/user/screens/drivers/driver_details_screen.dart';
import 'package:fleet_stack/modules/user/screens/drivers/driver_screen.dart';
import 'package:fleet_stack/modules/user/screens/home/home_screen.dart';
import 'package:fleet_stack/modules/user/screens/landmark/geofence.dart';
import 'package:fleet_stack/modules/user/screens/localization/localization.dart';
import 'package:fleet_stack/modules/user/screens/map/map.dart';
import 'package:fleet_stack/modules/user/screens/more/more_screen.dart';
import 'package:fleet_stack/modules/user/screens/notification/notification.dart';
import 'package:fleet_stack/modules/user/screens/notification/notification_settings_screen.dart';
import 'package:fleet_stack/modules/user/screens/notification/vehicle_toggle_screen.dart';
import 'package:fleet_stack/modules/user/screens/profile/profile_screen.dart';
import 'package:fleet_stack/modules/user/screens/sub_users/add_sub_user_screen.dart';
import 'package:fleet_stack/modules/user/screens/sub_users/sub_user_screen.dart';
import 'package:fleet_stack/modules/user/screens/support/support_screen.dart';
import 'package:fleet_stack/modules/user/screens/transaction/transaction.dart';
import 'package:fleet_stack/modules/user/screens/transaction/transaction_details.dart';
import 'package:fleet_stack/modules/user/screens/vehicles/add_vehicle_screen.dart';
import 'package:fleet_stack/modules/user/screens/vehicles/vehicle_details_screen.dart';
import 'package:fleet_stack/modules/user/screens/vehicles/vehicle_screen.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> userRoutes = [
  GoRoute(path: '/user', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/user/home', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/user/maps', builder: (_, __) => const MapScreen()),
  GoRoute(path: '/user/admin', builder: (_, __) => const AdminScreen()),
  GoRoute(
    path: '/user/share-track',
    builder: (_, __) => const ShareTrackScreen(),
  ),
  GoRoute(
    path: '/user/share-track/add',
    builder: (_, __) => const ShareTrackAddScreen(),
  ),
  GoRoute(path: '/user/vehicles', builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: '/user/vehicles/add',
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: '/user/vehicles/details/:id',
    builder: (context, state) => VehicleDetailsScreen(
      vehicleId: state.pathParameters['id']!,
      initialVehicle: state.extra is VehicleListItem
          ? state.extra as VehicleListItem
          : null,
    ),
  ),
  GoRoute(path: '/user/drivers', builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: '/user/drivers/add',
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(
    path: '/user/drivers/details/:id',
    builder: (context, state) => DriverDetailsScreen(
      driverId: state.pathParameters['id']!,
      initialDriver: state.extra is AdminDriverListItem
          ? state.extra as AdminDriverListItem
          : null,
    ),
  ),
  GoRoute(path: '/user/geofence', builder: (_, __) => const GeofenceScreen()),
  GoRoute(
    path: '/user/route-optimization',
    builder: (_, __) => const RouteOptimizationScreen(),
  ),
  GoRoute(path: '/user/support', builder: (_, __) => const SupportScreen()),
  GoRoute(path: '/user/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(
    path: '/user/generate-report',
    builder: (_, __) => const GenerateReportScreen(),
  ),
  GoRoute(
    path: '/user/localization',
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: '/user/notifications',
    builder: (_, __) => const NotificationsScreen(),
  ),
  GoRoute(
    path: '/user/notification-settings',
    builder: (_, __) => const NotificationSettingsScreen(),
  ),
  GoRoute(path: '/user/sub-users', builder: (_, __) => const SubUserScreen()),
  GoRoute(
    path: '/user/sub-users/add',
    builder: (_, __) => const AddSubUserScreen(),
  ),
  GoRoute(
    path: '/user/toggle/:eventType',
    builder: (context, state) =>
        VehicleToggleScreen(eventType: state.pathParameters['eventType']!),
  ),
  GoRoute(path: '/user/more', builder: (_, __) => const MoreScreen()),
  GoRoute(
    path: '/user/transactions',
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: '/user/transactions/details/:id',
    builder: (context, state) => TransactionDetailsScreen(
      transactionId: state.pathParameters['id']!,
      transaction: state.extra is AdminTransactionItem
          ? state.extra as AdminTransactionItem
          : null,
    ),
  ),
];
