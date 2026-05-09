import 'package:open_vts/modules/superadmin/components/admin/api_config/api_config.dart';
import 'package:open_vts/modules/superadmin/components/admin/application_setting/application_setting.dart';
import 'package:open_vts/modules/superadmin/components/admin/branding/branding_screen.dart';
import 'package:open_vts/modules/superadmin/components/admin/calender/calender_screen.dart';
import 'package:open_vts/modules/superadmin/components/admin/email_template_setting/email_template.dart';
import 'package:open_vts/modules/superadmin/components/admin/localization/localization.dart';
import 'package:open_vts/modules/superadmin/components/admin/payment_gateway_setting/payment_gateway_details.dart';
import 'package:open_vts/modules/superadmin/components/admin/payment_gateway_setting/payment_gateway_setting.dart';
import 'package:open_vts/modules/superadmin/components/admin/policy_edit/policy_edit.dart';
import 'package:open_vts/modules/superadmin/components/admin/push_notification_template/push_notification_template.dart';
import 'package:open_vts/modules/superadmin/components/admin/role/role.dart';
import 'package:open_vts/modules/superadmin/components/admin/server_status/server_status.dart';
import 'package:open_vts/modules/superadmin/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:open_vts/modules/superadmin/components/admin/ssl/ssl.dart';
import 'package:open_vts/modules/superadmin/components/admin/support/support.dart';
import 'package:open_vts/modules/superadmin/components/branding/branding_settings_screen.dart';
import 'package:open_vts/modules/superadmin/components/card/all_activities_screen.dart';
import 'package:open_vts/modules/superadmin/components/profile/profile_screen.dart';
import 'package:open_vts/modules/superadmin/components/transactions/record_manual_payment_screen.dart';
import 'package:open_vts/modules/superadmin/components/transactions/payments_screen.dart';
import 'package:open_vts/modules/superadmin/components/vehicle/VehicleDetailsScreen.dart';
import 'package:open_vts/modules/superadmin/components/vehicle/vehicle_screen.dart';
import 'package:open_vts/modules/superadmin/components/vehicle/widget/add_new_vehicle.dart';
import 'package:open_vts/modules/superadmin/screens/admin/add_new_admin.dart';
import 'package:open_vts/modules/superadmin/screens/admin/administrator_details_screen.dart';
import 'package:open_vts/app/router/app_route_paths.dart';
import 'package:open_vts/modules/superadmin/screens/admin/admins_screen.dart'
    show AdminScreen;
import 'package:open_vts/modules/superadmin/screens/dashboard/dashboard_screen.dart';
import 'package:open_vts/modules/superadmin/screens/home/home_screen.dart';
import 'package:open_vts/modules/superadmin/screens/map/map_screen.dart';
import 'package:open_vts/modules/superadmin/screens/more/more_screen.dart';
import 'package:open_vts/modules/superadmin/screens/notifications/superadmin_notifications_screen.dart';
import 'package:open_vts/modules/superadmin/screens/setting/superadmin_settings_screen.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> superAdminRoutes = [
  GoRoute(
    path: AppRoutePaths.superadmin,
    builder: (_, __) => const HomeScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminHome,
    builder: (_, __) => const HomeScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminDashboard,
    builder: (_, __) => const DashboardScreen(),
  ),

  /// ADMINS
  GoRoute(
    path: AppRoutePaths.superadminAdmins,
    builder: (_, __) => const AdminScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminAdminsAdd,
    builder: (_, __) => const AddNewAdminScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminAdminsDetailsPattern,
    name: 'superadminAdminDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final initialActive = state.extra is bool ? state.extra as bool : null;
      return AdministratorDetailsScreen(id: id, initialActive: initialActive);
    },
  ),

  /// SETTINGS
  GoRoute(
    path: AppRoutePaths.superadminSettings,
    builder: (_, __) => const SuperAdminSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminProfile,
    builder: (_, __) => const ProfileScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminBranding,
    builder: (_, __) => const BrandingScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminWhiteLabel,
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminApiConfig,
    builder: (_, __) => const ApiConfigSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminApplicationSettings,
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminEmailSettings,
    builder: (_, __) => const EmailTemplateSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminSmtpSettings,
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),

  /// PAYMENT
  GoRoute(
    path: AppRoutePaths.superadminPayments,
    builder: (_, __) => const PaymentsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminPaymentGateway,
    builder: (_, __) => const PaymentGatewaySettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminPaymentGatewayDetailsPattern,
    builder: (context, state) {
      final gatewayId = state.pathParameters['id']!;
      return PaymentGatewayDetailsScreen(gatewayId: gatewayId);
    },
  ),
  GoRoute(
    path: AppRoutePaths.superadminTransactionsRecordManual,
    builder: (_, __) => const RecordManualPaymentScreen(),
  ),

  /// ACTIVITY / NOTIFICATION
  GoRoute(
    path: AppRoutePaths.superadminNotificationSettings,
    builder: (_, __) => const PushNotificationTemplateSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminNotifications,
    builder: (_, __) => const SuperadminNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminAllActivities,
    builder: (context, state) {
      final type = (state.extra as Map?)?['type'] ?? 'Transactions';
      return AllActivitiesScreen(activityType: type);
    },
  ),

  /// VEHICLES
  GoRoute(
    path: AppRoutePaths.superadminVehicles,
    builder: (_, __) => const VehicleScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminVehiclesDetailsPattern,
    name: 'superadminVehicleDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return VehicleDetailsScreen(id: id);
    },
  ),

  /// SYSTEM
  GoRoute(
    path: AppRoutePaths.superadminCalendar,
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminServer,
    builder: (_, __) => const ServerStatusSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminSsl,
    builder: (_, __) => const SSLManagementScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminRoles,
    builder: (_, __) => const RolesScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminUserPolicy,
    builder: (_, __) => const PolicyEditScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminSupport,
    builder: (_, __) => const SupportScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminMore,
    builder: (_, __) => const MoreScreen(),
  ),
  GoRoute(
    path: AppRoutePaths.superadminMap,
    builder: (_, __) => const MapScreen(),
  ),
];
