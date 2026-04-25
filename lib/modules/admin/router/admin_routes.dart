import 'package:fleet_stack/modules/admin/components/admin/application_setting/application_setting.dart';
import 'package:fleet_stack/modules/admin/components/admin/branding/branding_screen.dart';
import 'package:fleet_stack/modules/admin/components/admin/localization/localization.dart';
import 'package:fleet_stack/modules/admin/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:fleet_stack/modules/admin/components/branding/branding_settings_screen.dart';
import 'package:fleet_stack/modules/admin/components/calender/calender_screen.dart';
import 'package:fleet_stack/modules/admin/components/card/all_activities_screen.dart';
import 'package:fleet_stack/modules/admin/components/notifications/notification_preferences_screen.dart';
import 'package:fleet_stack/modules/admin/components/profile/profile_screen.dart';
import 'package:fleet_stack/modules/admin/roles/roles_screen.dart';
import 'package:fleet_stack/modules/admin/screens/account/add_user_screen.dart';
import 'package:fleet_stack/modules/admin/screens/account/user_details_screen.dart';
import 'package:fleet_stack/modules/admin/screens/account/user.dart';
import 'package:fleet_stack/modules/admin/screens/analytics/analytics_screen.dart';
import 'package:fleet_stack/modules/admin/screens/devices/add_device_screen.dart';
import 'package:fleet_stack/modules/admin/screens/devices/device_screen.dart';
import 'package:fleet_stack/modules/admin/screens/logs/logs_screen.dart';
import 'package:fleet_stack/modules/admin/screens/map/map_screen.dart';
import 'package:fleet_stack/modules/admin/screens/more/more_screen.dart';
import 'package:fleet_stack/modules/admin/screens/notifications/notify_users_screen.dart';
import 'package:fleet_stack/modules/admin/screens/notifications/admin_notifications_screen.dart';
import 'package:fleet_stack/modules/admin/screens/payments/add_payment_screen.dart';
import 'package:fleet_stack/modules/admin/screens/payments/payment_screen.dart';
import 'package:fleet_stack/modules/admin/screens/plans/add_plan_screen.dart';
import 'package:fleet_stack/modules/admin/screens/plans/plans_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/add_renewal_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/renewal_screen.dart';
import 'package:fleet_stack/modules/admin/screens/setting/setting_screen.dart';
import 'package:fleet_stack/modules/admin/screens/sims/add_sim_screen.dart';
import 'package:fleet_stack/modules/admin/screens/sims/sim_screen.dart';
import 'package:fleet_stack/modules/admin/screens/support/support_screen.dart';
import 'package:fleet_stack/modules/admin/screens/teams/add_team_screen.dart';
import 'package:fleet_stack/modules/admin/screens/teams/team_details_screen.dart';
import 'package:fleet_stack/modules/admin/screens/teams/team_screen.dart';
import 'package:fleet_stack/modules/admin/screens/transactions/transaction_details_screen.dart';
import 'package:fleet_stack/modules/admin/screens/transactions/transaction_screen.dart';
import 'package:fleet_stack/modules/admin/screens/vehicles/vehicle_screen.dart';
import 'package:fleet_stack/modules/admin/screens/vehicles/vehicle_details_screen.dart';
import 'package:fleet_stack/modules/admin/screens/vehicles/add_vehicle_screen.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/driver_screen.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/add_driver_screen.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/driver_details_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/renew_device_screen.dart';
import 'package:fleet_stack/modules/admin/screens/payments/collect_payment_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/extend_license_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/suspend_access_screen.dart';
import 'package:fleet_stack/modules/admin/screens/renewals/send_reminder_screen.dart';
import 'package:fleet_stack/modules/admin/screens/plans/edit_plan_screen.dart';
import 'package:fleet_stack/modules/admin/screens/dashboard/dashboard_screen.dart';
import 'package:fleet_stack/modules/admin/screens/home/home_screen.dart';
import 'package:fleet_stack/modules/admin/screens/inventory/inventory_screen.dart';
import 'package:fleet_stack/modules/admin/screens/inventory/inventory_add_screen.dart';
import 'package:fleet_stack/modules/admin/screens/inventory/inventory_device_edit_screen.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> adminRoutes = [
  GoRoute(path: '/admin/home', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/admin', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/admin/dashboard', builder: (_, __) => const DashboardScreen()),
  GoRoute(path: '/admin/map', builder: (_, __) => const MapScreen()),
  GoRoute(path: '/admin/more', builder: (_, __) => const MoreScreen()),
  GoRoute(path: '/admin/users', builder: (_, __) => const UserScreen()),
  GoRoute(
    path: '/admin/users/details/:id',
    builder: (context, state) =>
        AdminUserDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: '/admin/vehicles', builder: (_, __) => const VehicleScreen()),
  GoRoute(
    path: '/admin/vehicles/details/:id',
    builder: (context, state) =>
        VehicleDetailsScreen(vehicleId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/admin/vehicles/add',
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(path: '/admin/drivers', builder: (_, __) => const DriverScreen()),
  GoRoute(
    path: '/admin/drivers/details/:id',
    builder: (context, state) =>
        AdminDriverDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/admin/drivers/add',
    builder: (_, __) => const AddDriverScreen(),
  ),
  GoRoute(path: '/admin/teams', builder: (_, __) => const TeamScreen()),
  GoRoute(
    path: '/admin/teams/details/:id',
    builder: (context, state) =>
        TeamDetailsScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(path: '/admin/inventory', builder: (_, __) => const InventoryScreen()),
  GoRoute(
    path: '/admin/inventory/add',
    builder: (_, __) => const InventoryAddScreen(),
  ),
  GoRoute(
    path: '/admin/inventory/device/:id',
    builder: (context, state) => InventoryDeviceEditScreen(
      deviceId: state.pathParameters['id']!,
      initialRaw: state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null,
    ),
  ),
  GoRoute(path: '/admin/teams/add', builder: (_, __) => const AddTeamScreen()),
  GoRoute(path: '/admin/devices', builder: (_, __) => const DeviceScreen()),
  GoRoute(
    path: '/admin/devices/add',
    builder: (_, __) => const AddDeviceScreen(),
  ),
  GoRoute(path: '/admin/sims', builder: (_, __) => const SimScreen()),
  GoRoute(path: '/admin/sims/add', builder: (_, __) => const AddSimScreen()),
  GoRoute(path: '/admin/payments', builder: (_, __) => const PaymentScreen()),
  GoRoute(
    path: '/admin/payments/add',
    builder: (_, __) => const AddPaymentScreen(),
  ),
  GoRoute(
    path: '/admin/transactions',
    builder: (_, __) => const TransactionScreen(),
  ),
  GoRoute(
    path: '/admin/calendar',
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(path: '/admin/logs', builder: (_, __) => const LogsScreen()),
  GoRoute(path: '/admin/plans', builder: (_, __) => const PlansScreen()),
  GoRoute(path: '/admin/plans/add', builder: (_, __) => const AddPlanScreen()),
  GoRoute(path: '/admin/settings', builder: (_, __) => const SettingsScreen()),
  GoRoute(path: '/admin/roles', builder: (_, __) => const RolesScreen()),
  GoRoute(
    path: '/admin/white-label',
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(path: '/admin/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(path: '/admin/branding', builder: (_, __) => const BrandingScreen()),
  GoRoute(
    path: '/admin/smtp-settings',
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),
  GoRoute(
    path: '/admin/localization',
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: '/admin/finance-dashboard',
    builder: (_, __) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: '/admin/application-settings',
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: '/admin/notifications',
    builder: (_, __) => const AdminNotificationsScreen(),
  ),
  GoRoute(
    path: '/admin/notify-user',
    builder: (_, __) => const NotifyUsersScreen(),
  ),
  GoRoute(
    path: '/admin/notification-preferences',
    builder: (_, __) => const NotificationPreferencesScreen(),
  ),
  GoRoute(path: '/admin/users/add', builder: (_, __) => const AddUserScreen()),

  GoRoute(
    path: '/admin/transactions/details/:id',
    builder: (context, state) => TransactionDetailsScreen(
      transactionId: state.pathParameters['id']!,
      initialRaw: state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null,
    ),
  ),
  GoRoute(path: '/admin/renewals', builder: (_, __) => const RenewalsScreen()),
  GoRoute(
    path: '/admin/renewals/add',
    builder: (_, __) => const AddRenewalScreen(),
  ),
  GoRoute(path: '/admin/support', builder: (_, __) => const SupportScreen()),
  GoRoute(
    path: '/admin/renewals/renew',
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ??
          []; // Safe fallback to empty list

      return RenewDeviceScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: '/admin/plans/edit/:id',
    builder: (context, state) {
      final plan = state.extra as Map<String, dynamic>;
      return EditPlanScreen(plan: plan);
    },
  ),

  GoRoute(
    path: '/admin/renewals/collect',
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return CollectPaymentScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: '/admin/renewals/extend',
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return ExtendLicenseScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: '/admin/renewals/suspend',
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SuspendAccessScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: '/admin/renewals/reminder',
    builder: (context, state) {
      final selectedDevices =
          (state.extra as List<Map<String, dynamic>>?) ?? [];
      return SendReminderScreen(selectedDevices: selectedDevices);
    },
  ),

  GoRoute(
    path: '/admin/all-activities',
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      final type =
          extra['type'] as String? ??
          'Vehicles'; // Default to 'Vehicles' if not provided
      return AllActivitiesScreen(activityType: type);
    },
  ),
];
