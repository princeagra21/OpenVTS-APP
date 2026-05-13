import 'package:open_vts/features/admin/presentation/components/admin/application_setting/application_setting.dart';
import 'package:open_vts/features/admin/presentation/components/admin/branding/branding_screen.dart';
import 'package:open_vts/features/admin/presentation/components/admin/localization/localization.dart';
import 'package:open_vts/features/admin/presentation/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:open_vts/features/admin/presentation/components/branding/branding_settings_screen.dart';
import 'package:open_vts/features/admin/presentation/components/calender/calender_screen.dart';
import 'package:open_vts/features/admin/presentation/components/card/all_activities_screen.dart';
import 'package:open_vts/features/admin/presentation/components/notifications/notification_preferences_screen.dart';
import 'package:open_vts/features/admin/presentation/components/profile/profile_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/roles/roles_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/account/add_user_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/account/user_details_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/account/user.dart';
import 'package:open_vts/features/admin/presentation/screens/analytics/analytics_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/devices/add_device_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/devices/device_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/logs/logs_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/map/map_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/more/more_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/notifications/notify_users_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/notifications/admin_notifications_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/payments/add_payment_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/payments/payment_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/plans/add_plan_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/plans/plans_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/add_renewal_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/renewal_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/setting/setting_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/sims/add_sim_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/sims/sim_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/support/support_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/teams/add_team_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/teams/team_details_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/teams/team_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/transactions/transaction_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/vehicles/vehicle_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/vehicles/vehicle_details_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/drivers/driver_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/drivers/add_driver_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/drivers/driver_details_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/renew_device_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/payments/collect_payment_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/extend_license_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/suspend_access_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/renewals/send_reminder_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/plans/edit_plan_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/home/home_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/inventory/inventory_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/inventory/inventory_add_screen.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/presentation/screens/inventory/inventory_device_edit_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/router/route_names.dart';

final List<GoRoute> adminRoutes = [
  GoRoute(path: AppRoutePaths.adminHome, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutePaths.admin, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutePaths.adminDashboard, builder: (_, __) => const DashboardScreen()),
  GoRoute(path: AppRoutePaths.adminMap, builder: (_, __) => const MapScreen()),
  GoRoute(path: AppRoutePaths.adminMore, builder: (_, __) => const MoreScreen()),
  GoRoute(path: AppRoutePaths.adminUsers, builder: (_, __) => const UserScreen()),
  GoRoute(
    path: AppRoutePaths.adminUsersDetailsPattern,
    builder: (context, state) =>
        UserDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: AppRoutePaths.adminVehicles, builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: AppRoutePaths.adminVehiclesDetailsPattern,
    builder: (context, state) =>
        VehicleDetailsScreen(vehicleId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutePaths.adminVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminDrivers, builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: AppRoutePaths.adminDriversDetailsPattern,
    builder: (context, state) =>
        AdminDriverDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutePaths.adminDriversAdd,
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminTeams, builder: (_, __) => const TeamScreen()),
  GoRoute(
    path: AppRoutePaths.adminTeamsDetailsPattern,
    builder: (context, state) =>
        TeamDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: AppRoutePaths.adminInventory, builder: (_, __) => const InventoryScreen()),
  GoRoute(
    path: AppRoutePaths.adminInventoryAdd,
    builder: (_, __) => const InventoryAddScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminInventoryDevicePattern,
    builder: (context, state) => InventoryDeviceEditScreen(
      deviceId: state.pathParameters['id']!,
      initialDevice: state.extra is AdminDeviceListItem
          ? state.extra as AdminDeviceListItem
          : null,
    ),
  ),
  GoRoute(path: AppRoutePaths.adminTeamsAdd, builder: (_, __) => const AddTeamScreen()),
  GoRoute(path: AppRoutePaths.adminDevices, builder: (_, __) => const DeviceScreen()),
  GoRoute(
    path: AppRoutePaths.adminDevicesAdd,
    builder: (_, __) => const AddDeviceScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminSims, builder: (_, __) => const SimScreen()),
  GoRoute(path: AppRoutePaths.adminSimsAdd, builder: (_, __) => const AddSimScreen()),
  GoRoute(path: AppRoutePaths.adminPayments, builder: (_, __) => const PaymentScreen()),
  GoRoute(
    path: AppRoutePaths.adminPaymentsAdd,
    builder: (_, __) => const AddPaymentScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminTransactions,
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminCalendar,
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminLogs, builder: (_, __) => const LogsScreen()),
  GoRoute(path: AppRoutePaths.adminPlans, builder: (_, __) => const PlansScreen()),
  GoRoute(path: AppRoutePaths.adminPlansAdd, builder: (_, __) => const AddPlanScreen()),
  GoRoute(path: AppRoutePaths.adminSettings, builder: (_, __) => const SettingsScreen()),
  GoRoute(path: AppRoutePaths.adminRoles, builder: (_, __) => const RolesScreen()),
  GoRoute(
    path: AppRoutePaths.adminWhiteLabel,
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminProfile, builder: (_, __) => const ProfileScreen()),
  GoRoute(path: AppRoutePaths.adminBranding, builder: (_, __) => const BrandingScreen()),
  GoRoute(
    path: AppRoutePaths.adminSmtpSettings,
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminFinanceDashboard,
    builder: (_, __) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminApplicationSettings,
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminNotifications,
    builder: (_, __) => const AdminNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminNotifyUser,
    builder: (_, __) => const NotifyUsersScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.adminNotificationPreferences,
    builder: (_, __) => const NotificationPreferencesScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminUsersAdd, builder: (_, __) => const AddUserScreen()),

  GoRoute(
    path: AppRoutePaths.adminTransactionsDetailsPattern,
    builder: (context, state) {
      final extra = state.extra;
      return TransactionDetailsScreen(
        transactionId: state.pathParameters['id']!,
        initialRaw: extra is AdminDeviceListItem
            ? Map<String, dynamic>.from(extra.raw)
            : extra is Map
                ? Map<String, dynamic>.from(extra.cast())
                : null,
      );
    },
  ),
  GoRoute(path: AppRoutePaths.adminRenewals, builder: (_, __) => const RenewalsScreen()),
  GoRoute(
    path: AppRoutePaths.adminRenewalsAdd,
    builder: (_, __) => const AddRenewalScreen(),
  ),
  GoRoute(path: AppRoutePaths.adminSupport, builder: (_, __) => const SupportScreen()),
  GoRoute(
    path: AppRoutePaths.adminRenewalsRenew,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ??
          []; // Safe fallback to empty list

      return RenewDeviceScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminPlansEditPattern,
    builder: (context, state) {
      final plan = state.extra as Map<String, dynamic>;
      return EditPlanScreen(plan: plan);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminRenewalsCollect,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return CollectPaymentScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminRenewalsExtend,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return ExtendLicenseScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminRenewalsSuspend,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SuspendAccessScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminRenewalsReminder,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SendReminderScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutePaths.adminAllActivities,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final type =
          extra['type'] as String? ??
          'Vehicles'; // Default to 'Vehicles' if not provided
      return AllActivitiesScreen(activityType: type);
    },
  ),
];
