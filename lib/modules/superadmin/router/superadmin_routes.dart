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
import 'package:open_vts/core/navigation/app_routes.dart';
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
  GoRoute(path: AppRoutes.superadmin, builder: (_, __) => const HomeScreen()),
  GoRoute(path: AppRoutes.superadminHome, builder: (_, __) => const HomeScreen()),
  GoRoute(
    path: AppRoutes.superadminDashboard,
    builder: (_, __) => const DashboardScreen(),
  ),

  /// ADMINS
  GoRoute(path: AppRoutes.superadminAdmins, builder: (_, __) => const AdminScreen()),
  GoRoute(
    path: AppRoutes.superadminAdminsAdd,
    builder: (_, __) => const AddNewAdminScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminAdminsDetailsPattern,
    name: 'superadminAdminDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final initialActive = state.extra is bool ? state.extra as bool : null;
      return AdministratorDetailsScreen(
        id: id,
        initialActive: initialActive,
      );
    },
  ),

  /// SETTINGS
  GoRoute(
    path: AppRoutes.superadminSettings,
    builder: (_, __) => const SuperAdminSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminProfile,
    builder: (_, __) => const ProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminBranding,
    builder: (_, __) => const BrandingScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminWhiteLabel,
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminApiConfig,
    builder: (_, __) => const ApiConfigSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminApplicationSettings,
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminLocalization,
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminEmailSettings,
    builder: (_, __) => const EmailTemplateSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminSmtpSettings,
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),

  /// PAYMENT
  GoRoute(
    path: AppRoutes.superadminPayments,
    builder: (_, __) => const PaymentsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminPaymentGateway,
    builder: (_, __) => const PaymentGatewaySettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminPaymentGatewayDetailsPattern,
    builder: (context, state) {
      final gatewayId = state.pathParameters['id']!;
      return PaymentGatewayDetailsScreen(gatewayId: gatewayId);
    },
  ),
  GoRoute(
    path: AppRoutes.superadminTransactionsRecordManual,
    builder: (_, __) => const RecordManualPaymentScreen(),
  ),

  /// ACTIVITY / NOTIFICATION
  GoRoute(
    path: AppRoutes.superadminNotificationSettings,
    builder: (_, __) => const PushNotificationTemplateSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminNotifications,
    builder: (_, __) => const SuperadminNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminAllActivities,
    builder: (context, state) {
      final type = (state.extra as Map?)?['type'] ?? 'Transactions';
      return AllActivitiesScreen(activityType: type);
    },
  ),

  /// VEHICLES
  GoRoute(
    path: AppRoutes.superadminVehicles,
    builder: (_, __) => const VehicleScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminVehiclesAdd,
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminVehiclesDetailsPattern,
    name: 'superadminVehicleDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return VehicleDetailsScreen(id: id);
    },
  ),

  /// SYSTEM
  GoRoute(
    path: AppRoutes.superadminCalendar,
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminServer,
    builder: (_, __) => const ServerStatusScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminSsl,
    builder: (_, __) => const SSLManagementScreen(),
  ),
  GoRoute(path: AppRoutes.superadminRoles, builder: (_, __) => const RolesScreen()),
  GoRoute(
    path: AppRoutes.superadminUserPolicy,
    builder: (_, __) => const PolicyEditScreen(),
  ),
  GoRoute(
    path: AppRoutes.superadminSupport,
    builder: (_, __) => const SupportScreen(),
  ),
  GoRoute(path: AppRoutes.superadminMore, builder: (_, __) => const MoreScreen()),
  GoRoute(path: AppRoutes.superadminMap, builder: (_, __) => const MapScreen()),
];
