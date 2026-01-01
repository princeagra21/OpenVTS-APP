import 'package:fleet_stack/modules/superadmin/components/admin/api_config/api_config.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/application_setting/application_setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/branding/branding_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/calender/calender_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/email_template_setting/email_template.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/localization/localization.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/payment_gateway_setting/payment_gateway_details.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/payment_gateway_setting/payment_gateway_setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/policy_edit/policy_edit.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/push_notification_template/push_notification_template.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/role/role.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/server_status/server_status.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/smpt_configuration_setting/smpt_configuration_setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/ssl/ssl.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/support/support.dart';
import 'package:fleet_stack/modules/superadmin/components/branding/branding_settings_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/card/all_activities_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/profile/profile_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/VehicleDetailsScreen.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/vehicle_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/vehicle/widget/add_new_vehicle.dart';
import 'package:fleet_stack/modules/superadmin/screens/admin/add_new_admin.dart';
import 'package:fleet_stack/modules/superadmin/screens/admin/administrator_details_screen.dart';
import 'package:fleet_stack/modules/superadmin/screens/admin/admins_screen.dart' show AdminScreen;
import 'package:fleet_stack/modules/superadmin/screens/home/home_screen.dart';
import 'package:fleet_stack/modules/superadmin/screens/map/map_screen.dart';
import 'package:fleet_stack/modules/superadmin/screens/more/more_screen.dart';
import 'package:fleet_stack/modules/superadmin/screens/setting/setting_screen.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> superAdminRoutes = [
  GoRoute(
    path: '/superadmin',
    builder: (_, __) => const HomeScreen(),
  ),
  GoRoute(
    path: '/superadmin/home',
    builder: (_, __) => const HomeScreen(),
  ),

  /// ADMINS
  GoRoute(
    path: '/superadmin/admins',
    builder: (_, __) => const AdminScreen(),
  ),
  GoRoute(
    path: '/superadmin/admins/add',
    builder: (_, __) => const AddNewAdminScreen(),
  ),
  GoRoute(
    path: '/superadmin/admins/details/:id',
    name: 'superadminAdminDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return AdministratorDetailsScreen(id: id);
    },
  ),

  /// SETTINGS
  GoRoute(
    path: '/superadmin/settings',
    builder: (_, __) => const SettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/profile',
    builder: (_, __) => const ProfileScreen(),
  ),
  GoRoute(
    path: '/superadmin/branding',
    builder: (_, __) => const BrandingScreen(),
  ),
  GoRoute(
    path: '/superadmin/white-label',
    builder: (_, __) => const BrandingSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/api-config',
    builder: (_, __) => const ApiConfigSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/application-settings',
    builder: (_, __) => const ApplicationSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/localization',
    builder: (_, __) => const LocalizationSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/email-settings',
    builder: (_, __) => const EmailTemplateSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/smtp-settings',
    builder: (_, __) => const SmtpConfigSettingsScreen(),
  ),

  /// PAYMENT
  GoRoute(
    path: '/superadmin/payment-gateway',
    builder: (_, __) => const PaymentGatewaySettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/payment-gateway/:id',
    builder: (context, state) {
      final gatewayId = state.pathParameters['id']!;
      return PaymentGatewayDetailsScreen(gatewayId: gatewayId);
    },
  ),

  /// ACTIVITY / NOTIFICATION
  GoRoute(
    path: '/superadmin/notification-settings',
    builder: (_, __) =>
        const PushNotificationTemplateSettingsScreen(),
  ),
  GoRoute(
    path: '/superadmin/all-activities',
    builder: (context, state) {
      final type = (state.extra as Map?)?['type'] ?? 'Transactions';
      return AllActivitiesScreen(activityType: type);
    },
  ),

  /// VEHICLES
  GoRoute(
    path: '/superadmin/vehicles',
    builder: (_, __) => const VehicleScreen(),
  ),
  GoRoute(
    path: '/superadmin/vehicles/add',
    builder: (_, __) => const AddVehicleScreen(),
  ),
  GoRoute(
    path: '/superadmin/vehicles/details/:id',
    name: 'superadminVehicleDetails',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return VehicleDetailsScreen(id: id);
    },
  ),

  /// SYSTEM
  GoRoute(
    path: '/superadmin/calendar',
    builder: (_, __) => const EventCalendarScreen(),
  ),
  GoRoute(
    path: '/superadmin/server',
    builder: (_, __) => const ServerStatusScreen(),
  ),
  GoRoute(
    path: '/superadmin/ssl',
    builder: (_, __) => const SSLManagementScreen(),
  ),
  GoRoute(
    path: '/superadmin/roles',
    builder: (_, __) => const RolesScreen(),
  ),
  GoRoute(
    path: '/superadmin/user-policy',
    builder: (_, __) => const PolicyEditScreen(),
  ),
  GoRoute(
    path: '/superadmin/support',
    builder: (_, __) => const SupportScreen(),
  ),
  GoRoute(
    path: '/superadmin/more',
    builder: (_, __) => const MoreScreen(),
  ),
  GoRoute(
    path: '/superadmin/map',
    builder: (_, __) => const MapScreen(),
  ),
];