class AppRoutePaths {
  const AppRoutePaths.internal();

  static const String root = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';

  // Admin
  static const String admin = '/admin';
  static const String adminHome = '/admin/home';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminMap = '/admin/map';
  static const String adminMore = '/admin/more';
  static const String adminUsers = '/admin/users';
  static const String adminUsersAdd = '/admin/users/add';
  static const String adminUsersDetailsPattern = '/admin/users/details/:id';
  static String adminUsersDetails(String id) => '/admin/users/details/$id';
  static const String adminVehicles = '/admin/vehicles';
  static const String adminVehiclesAdd = '/admin/vehicles/add';
  static const String adminVehiclesDetailsPattern =
      '/admin/vehicles/details/:id';
  static String adminVehiclesDetails(String id) =>
      '/admin/vehicles/details/$id';
  static const String adminDrivers = '/admin/drivers';
  static const String adminDriversAdd = '/admin/drivers/add';
  static const String adminDriversDetailsPattern = '/admin/drivers/details/:id';
  static String adminDriversDetails(String id) => '/admin/drivers/details/$id';
  static const String adminTeams = '/admin/teams';
  static const String adminTeamsAdd = '/admin/teams/add';
  static const String adminTeamsDetailsPattern = '/admin/teams/details/:id';
  static String adminTeamsDetails(String id) => '/admin/teams/details/$id';
  static const String adminInventory = '/admin/inventory';
  static const String adminInventoryAdd = '/admin/inventory/add';
  static const String adminInventoryDevicePattern =
      '/admin/inventory/device/:id';
  static String adminInventoryDevice(String id) =>
      '/admin/inventory/device/$id';
  static const String adminDevices = '/admin/devices';
  static const String adminDevicesAdd = '/admin/devices/add';
  static const String adminSims = '/admin/sims';
  static const String adminSimsAdd = '/admin/sims/add';
  static const String adminPayments = '/admin/payments';
  static const String adminPaymentsAdd = '/admin/payments/add';
  static const String adminTransactions = '/admin/transactions';
  static const String adminTransactionsDetailsPattern =
      '/admin/transactions/details/:id';
  static String adminTransactionsDetails(String id) =>
      '/admin/transactions/details/$id';
  static const String adminCalendar = '/admin/calendar';
  static const String adminLogs = '/admin/logs';
  static const String adminPlans = '/admin/plans';
  static const String adminPlansAdd = '/admin/plans/add';
  static const String adminPlansEditPattern = '/admin/plans/edit/:id';
  static String adminPlansEdit(String id) => '/admin/plans/edit/$id';
  static const String adminSettings = '/admin/settings';
  static const String adminRoles = '/admin/roles';
  static const String adminWhiteLabel = '/admin/white-label';
  static const String adminProfile = '/admin/profile';
  static const String adminBranding = '/admin/branding';
  static const String adminSmtpSettings = '/admin/smtp-settings';
  static const String adminLocalization = '/admin/localization';
  static const String adminFinanceDashboard = '/admin/finance-dashboard';
  static const String adminApplicationSettings = '/admin/application-settings';
  static const String adminNotifications = '/admin/notifications';
  static const String adminNotifyUser = '/admin/notify-user';
  static const String adminApiConfig = '/admin/api-config';
  static const String adminNotificationSettings =
      '/admin/notification-settings';
  static const String adminEmailSettings = '/admin/email-settings';
  static const String adminNotificationPreferences =
      '/admin/notification-preferences';
  static const String adminUserPolicy = '/admin/user-policy';
  static const String adminPaymentGateway = '/admin/payment-gateway';
  static const String adminServer = '/admin/server';
  static const String adminSsl = '/admin/ssl';
  static const String adminAllTransactions = '/admin/all-transactions';
  static const String adminsDetailsLegacyPrefix = '/admins/details';
  static const String adminVehiclesDetailsPrefix = '/admin/vehicles/details/';
  static const String adminDriversDetailsPrefix = '/admin/drivers/details/';
  static const String adminRenewals = '/admin/renewals';
  static const String adminRenewalsAdd = '/admin/renewals/add';
  static const String adminRenewalsRenew = '/admin/renewals/renew';
  static const String adminRenewalsCollect = '/admin/renewals/collect';
  static const String adminRenewalsExtend = '/admin/renewals/extend';
  static const String adminRenewalsSuspend = '/admin/renewals/suspend';
  static const String adminRenewalsReminder = '/admin/renewals/reminder';
  static const String adminSupport = '/admin/support';
  static const String adminAllActivities = '/admin/all-activities';

  // Superadmin
  static const String superadmin = '/superadmin';
  static const String superadminHome = '/superadmin/home';
  static const String superadminDashboard = '/superadmin/dashboard';
  static const String superadminAdmins = '/superadmin/admins';
  static const String superadminAdminsAdd = '/superadmin/admins/add';
  static const String superadminAdminsDetailsPattern =
      '/superadmin/admins/details/:id';
  static String superadminAdminsDetails(String id) =>
      '/superadmin/admins/details/$id';
  static const String superadminSettings = '/superadmin/settings';
  static const String superadminProfile = '/superadmin/profile';
  static const String superadminBranding = '/superadmin/branding';
  static const String superadminWhiteLabel = '/superadmin/white-label';
  static const String superadminApiConfig = '/superadmin/api-config';
  static const String superadminApplicationSettings =
      '/superadmin/application-settings';
  static const String superadminLocalization = '/superadmin/localization';
  static const String superadminEmailSettings = '/superadmin/email-settings';
  static const String superadminSmtpSettings = '/superadmin/smtp-settings';
  static const String superadminPayments = '/superadmin/payments';
  static const String superadminAllTransactions =
      '/superadmin/all-transactions';
  static const String superadminPaymentGateway = '/superadmin/payment-gateway';
  static const String superadminPaymentGatewayDetailsPattern =
      '/superadmin/payment-gateway/:id';
  static String superadminPaymentGatewayDetails(String id) =>
      '/superadmin/payment-gateway/$id';
  static const String superadminTransactionsRecordManual =
      '/superadmin/transactions/record-manual';
  static const String superadminNotificationSettings =
      '/superadmin/notification-settings';
  static const String superadminNotifications = '/superadmin/notifications';
  static const String superadminAllActivities = '/superadmin/all-activities';
  static const String superadminVehicles = '/superadmin/vehicles';
  static const String superadminVehiclesAdd = '/superadmin/vehicles/add';
  static const String superadminVehiclesDetailsPattern =
      '/superadmin/vehicles/details/:id';
  static String superadminVehiclesDetails(String id) =>
      '/superadmin/vehicles/details/$id';
  static const String superadminAdminsDetailsPrefix =
      '/superadmin/admins/details';
  static const String superadminVehiclesDetailsPrefix =
      '/superadmin/vehicles/details/';
  static const String superadminCalendar = '/superadmin/calendar';
  static const String superadminServer = '/superadmin/server';
  static const String superadminSsl = '/superadmin/ssl';
  static const String superadminRoles = '/superadmin/roles';
  static const String superadminUserPolicy = '/superadmin/user-policy';
  static const String superadminSupport = '/superadmin/support';
  static const String superadminMore = '/superadmin/more';
  static const String superadminMap = '/superadmin/map';

  // User
  static const String user = '/user';
  static const String userHome = '/user/home';
  static const String userDashboard = '/user/dashboard';
  static const String userMaps = '/user/maps';
  static const String userAdmin = '/user/admin';
  static const String userAccounts = '/user/accounts';
  static const String userShareTrack = '/user/share-track';
  static const String userShareTrackAdd = '/user/share-track/add';
  static const String userVehicles = '/user/vehicles';
  static const String userVehiclesAdd = '/user/vehicles/add';
  static const String userVehiclesDetailsPattern = '/user/vehicles/details/:id';
  static String userVehiclesDetails(String id) => '/user/vehicles/details/$id';
  static const String userDrivers = '/user/drivers';
  static const String userDriversAdd = '/user/drivers/add';
  static const String userDriversDetailsPattern = '/user/drivers/details/:id';
  static String userDriversDetails(String id) => '/user/drivers/details/$id';
  static const String userDriversEditPattern = '/user/drivers/edit/:id';
  static String userDriversEdit(String id) => '/user/drivers/edit/$id';
  static const String userGeofence = '/user/geofence';
  static const String userRouteOptimization = '/user/route-optimization';
  static const String userSupport = '/user/support';
  static const String userSettings = '/user/settings';
  static const String userProfile = '/user/profile';
  static const String userWhiteLabel = '/user/white-label';
  static const String userBranding = '/user/branding';
  static const String userApiConfig = '/user/api-config';
  static const String userApplicationSettings = '/user/application-settings';
  static const String userEmailSettings = '/user/email-settings';
  static const String userSmtpSettings = '/user/smtp-settings';
  static const String userUserPolicy = '/user/user-policy';
  static const String userPaymentGateway = '/user/payment-gateway';
  static const String userServer = '/user/server';
  static const String userCalendar = '/user/calendar';
  static const String userRoles = '/user/roles';
  static const String userSsl = '/user/ssl';
  static const String userAllTransactions = '/user/all-transactions';
  static const String userAllActivities = '/user/all-activities';
  static const String usersDetailsLegacyPrefix = '/users/details';
  static const String userDriversDetailsPrefix = '/user/drivers/details/';
  static const String userVehiclesDetailsPrefix = '/user/vehicles/details/';
  static const String userGenerateReport = '/user/generate-report';
  static const String userLocalization = '/user/localization';
  static const String userNotificationsPush = '/user/notifications/push';
  static const String userNotifications = '/user/notifications';
  static const String userNotificationSettings = '/user/notification-settings';
  static const String userSubUsers = '/user/sub-users';
  static const String userSubUsersAdd = '/user/sub-users/add';
  static const String userSubUsersDetailsPattern =
      '/user/sub-users/details/:id';
  static String userSubUsersDetails(String id) => '/user/sub-users/details/$id';
  static const String userSubUsersEditPattern = '/user/sub-users/edit/:id';
  static String userSubUsersEdit(String id) => '/user/sub-users/edit/$id';
  static const String userToggleEventTypePattern = '/user/toggle/:eventType';
  static String userToggleEventType(String eventType) =>
      '/user/toggle/$eventType';
  static const String userMore = '/user/more';
  static const String userTransactions = '/user/transactions';
  static const String userTransactionsDetailsPattern =
      '/user/transactions/details/:id';
  static String userTransactionsDetails(String id) =>
      '/user/transactions/details/$id';

  // Driver
  static const String driver = '/driver';
  static const String driverHome = '/driver/home';
  static const String driverMap = '/driver/map';
  static const String driverMore = '/driver/more';
  static const String driverProfile = '/driver/profile';
  static const String driverNotifications = '/driver/notifications';
}

/// Architecture-level route aliases used by new feature-first code.
abstract class RouteNames {
  const RouteNames._();

  static const String splash = AppRoutePaths.onboarding;
  static const String login = AppRoutePaths.login;
  static const String superadminDashboard = AppRoutePaths.superadminDashboard;
  static const String adminDashboard = AppRoutePaths.adminDashboard;
  static const String userDashboard = AppRoutePaths.userDashboard;
  static const String superadminMap = AppRoutePaths.superadminMap;
  static const String adminMap = AppRoutePaths.adminMap;
  static const String userMap = AppRoutePaths.userMaps;
}
