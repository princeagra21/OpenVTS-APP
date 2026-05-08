import 'package:open_vts/modules/admin/components/admin/application_setting/application_setting.dart';
import 'package:open_vts/modules/admin/components/admin/branding/branding_screen.dart';
import 'package:open_vts/modules/admin/components/admin/localization/localization.dart';
import 'package:open_vts/modules/admin/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:open_vts/modules/admin/components/branding/branding_settings_screen.dart';
import 'package:open_vts/modules/admin/components/calender/calender_screen.dart';
import 'package:open_vts/modules/admin/components/card/all_activities_screen.dart';
import 'package:open_vts/modules/admin/components/notifications/notification_preferences_screen.dart';
import 'package:open_vts/modules/admin/components/profile/profile_screen.dart';
import 'package:open_vts/modules/admin/roles/roles_screen.dart';
import 'package:open_vts/modules/admin/screens/account/add_user_screen.dart';
import 'package:open_vts/modules/admin/screens/account/user_details_screen.dart';
import 'package:open_vts/modules/admin/screens/account/user.dart';
import 'package:open_vts/modules/admin/screens/analytics/analytics_screen.dart';
import 'package:open_vts/modules/admin/screens/devices/add_device_screen.dart';
import 'package:open_vts/modules/admin/screens/devices/device_screen.dart';
import 'package:open_vts/modules/admin/screens/logs/logs_screen.dart';
import 'package:open_vts/modules/admin/screens/map/map_screen.dart';
import 'package:open_vts/modules/admin/screens/more/more_screen.dart';
import 'package:open_vts/modules/admin/screens/notifications/notify_users_screen.dart';
import 'package:open_vts/modules/admin/screens/notifications/admin_notifications_screen.dart';
import 'package:open_vts/modules/admin/screens/payments/add_payment_screen.dart';
import 'package:open_vts/modules/admin/screens/payments/payment_screen.dart';
import 'package:open_vts/modules/admin/screens/plans/add_plan_screen.dart';
import 'package:open_vts/modules/admin/screens/plans/plans_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/add_renewal_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/renewal_screen.dart';
import 'package:open_vts/modules/admin/screens/setting/setting_screen.dart';
import 'package:open_vts/modules/admin/screens/sims/add_sim_screen.dart';
import 'package:open_vts/modules/admin/screens/sims/sim_screen.dart';
import 'package:open_vts/modules/admin/screens/support/support_screen.dart';
import 'package:open_vts/modules/admin/screens/teams/add_team_screen.dart';
import 'package:open_vts/modules/admin/screens/teams/team_details_screen.dart';
import 'package:open_vts/modules/admin/screens/teams/team_screen.dart';
import 'package:open_vts/modules/admin/screens/transactions/transaction_details_screen.dart';
import 'package:open_vts/modules/admin/screens/transactions/transaction_screen.dart';
import 'package:open_vts/modules/admin/screens/vehicles/vehicle_screen.dart';
import 'package:open_vts/modules/admin/screens/vehicles/vehicle_details_screen.dart';
import 'package:open_vts/modules/admin/screens/vehicles/add_vehicle_screen.dart';
import 'package:open_vts/modules/admin/screens/drivers/driver_screen.dart';
import 'package:open_vts/modules/admin/screens/drivers/add_driver_screen.dart';
import 'package:open_vts/modules/admin/screens/drivers/driver_details_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/renew_device_screen.dart';
import 'package:open_vts/modules/admin/screens/payments/collect_payment_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/extend_license_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/suspend_access_screen.dart';
import 'package:open_vts/modules/admin/screens/renewals/send_reminder_screen.dart';
import 'package:open_vts/modules/admin/screens/plans/edit_plan_screen.dart';
import 'package:open_vts/modules/admin/screens/dashboard/dashboard_screen.dart';
import 'package:open_vts/modules/admin/screens/home/home_screen.dart';
import 'package:open_vts/modules/admin/screens/inventory/inventory_screen.dart';
import 'package:open_vts/modules/admin/screens/inventory/inventory_add_screen.dart';
import 'package:open_vts/modules/admin/screens/inventory/inventory_device_edit_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/navigation/app_routes.dart';

final List<GoRoute> adminRoutes = [
  GoRoute(path: AppRoutes.adminHome, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutes.admin, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutes.adminDashboard, builder: (_, __) => const DashboardScreen()),
  GoRoute(path: AppRoutes.adminMap, builder: (_, __) => const MapScreen()),
  GoRoute(path: AppRoutes.adminMore, builder: (_, __) => const MoreScreen()),
  GoRoute(path: AppRoutes.adminUsers, builder: (_, __) => const UserScreen()),
  GoRoute(
    path: AppRoutes.adminUsersDetailsPattern,
    builder: (context, state) =>
        UserDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: AppRoutes.adminVehicles, builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: AppRoutes.adminVehiclesDetailsPattern,
    builder: (context, state) =>
        VehicleDetailsScreen(vehicleId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutes.adminVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(path: AppRoutes.adminDrivers, builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: AppRoutes.adminDriversDetailsPattern,
    builder: (context, state) =>
        AdminDriverDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppRoutes.adminDriversAdd,
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(path: AppRoutes.adminTeams, builder: (_, __) => const TeamScreen()),
  GoRoute(
    path: AppRoutes.adminTeamsDetailsPattern,
    builder: (context, state) =>
        TeamDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: AppRoutes.adminInventory, builder: (_, __) => const InventoryScreen()),
  GoRoute(
    path: AppRoutes.adminInventoryAdd,
    builder: (_, __) => const InventoryAddScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminInventoryDevicePattern,
    builder: (context, state) => InventoryDeviceEditScreen(
      deviceId: state.pathParameters['id']!,
      initialRaw: state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null,
    ),
  ),
  GoRoute(path: AppRoutes.adminTeamsAdd, builder: (_, __) => const AddTeamScreen()),
  GoRoute(path: AppRoutes.adminDevices, builder: (_, __) => const DeviceScreen()),
  GoRoute(
    path: AppRoutes.adminDevicesAdd,
    builder: (_, __) => const AddDeviceScreen(),
  ),
  GoRoute(path: AppRoutes.adminSims, builder: (_, __) => const SimScreen()),
  GoRoute(path: AppRoutes.adminSimsAdd, builder: (_, __) => const AddSimScreen()),
  GoRoute(path: AppRoutes.adminPayments, builder: (_, __) => const PaymentScreen()),
  GoRoute(
    path: AppRoutes.adminPaymentsAdd,
    builder: (_, __) => const AddPaymentScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminTransactions,
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminCalendar,
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(path: AppRoutes.adminLogs, builder: (_, __) => const LogsScreen()),
  GoRoute(path: AppRoutes.adminPlans, builder: (_, __) => const PlansScreen()),
  GoRoute(path: AppRoutes.adminPlansAdd, builder: (_, __) => const AddPlanScreen()),
  GoRoute(path: AppRoutes.adminSettings, builder: (_, __) => const SettingsScreen()),
  GoRoute(path: AppRoutes.adminRoles, builder: (_, __) => const RolesScreen()),
  GoRoute(
    path: AppRoutes.adminWhiteLabel,
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(path: AppRoutes.adminProfile, builder: (_, __) => const ProfileScreen()),
  GoRoute(path: AppRoutes.adminBranding, builder: (_, __) => const BrandingScreen()),
  GoRoute(
    path: AppRoutes.adminSmtpSettings,
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminFinanceDashboard,
    builder: (_, __) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminApplicationSettings,
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminNotifications,
    builder: (_, __) => const AdminNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminNotifyUser,
    builder: (_, __) => const NotifyUsersScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminNotificationPreferences,
    builder: (_, __) => const NotificationPreferencesScreen(),
  ),
  GoRoute(path: AppRoutes.adminUsersAdd, builder: (_, __) => const AddUserScreen()),

  GoRoute(
    path: AppRoutes.adminTransactionsDetailsPattern,
    builder: (context, state) => TransactionDetailsScreen(
      transactionId: state.pathParameters['id']!,
      initialRaw: state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null,
    ),
  ),
  GoRoute(path: AppRoutes.adminRenewals, builder: (_, __) => const RenewalsScreen()),
  GoRoute(
    path: AppRoutes.adminRenewalsAdd,
    builder: (_, __) => const AddRenewalScreen(),
  ),
  GoRoute(path: AppRoutes.adminSupport, builder: (_, __) => const SupportScreen()),
  GoRoute(
    path: AppRoutes.adminRenewalsRenew,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ??
          []; // Safe fallback to empty list

      return RenewDeviceScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutes.adminPlansEditPattern,
    builder: (context, state) {
      final plan = state.extra as Map<String, dynamic>;
      return EditPlanScreen(plan: plan);
    },
  ),

  GoRoute(
    path: AppRoutes.adminRenewalsCollect,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return CollectPaymentScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutes.adminRenewalsExtend,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return ExtendLicenseScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutes.adminRenewalsSuspend,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SuspendAccessScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutes.adminRenewalsReminder,
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SendReminderScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: AppRoutes.adminAllActivities,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final type =
          extra['type'] as String? ??
          'Vehicles'; // Default to 'Vehicles' if not provided
      return AllActivitiesScreen(activityType: type);
    },
  ),
];
