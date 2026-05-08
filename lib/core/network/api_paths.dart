class ApiPaths {
  static String path(String value) {
    final v = value.trim();
    if (v.isEmpty) return '/';
    return v.startsWith('/') ? v : '/$v';
  }

  static const String adminPrefix = AdminApiPaths.prefix;
  static const String userPrefix = UserApiPaths.prefix;
  static const String superadminPrefix = SuperadminApiPaths.prefix;

  static String auth(String suffix) => AuthApiPaths.withSuffix(suffix);
  static String user(String suffix) => UserApiPaths.withSuffix(suffix);
  static String admin(String suffix) => AdminApiPaths.withSuffix(suffix);
  static String superadmin(String suffix) =>
      SuperadminApiPaths.withSuffix(suffix);

  // Backward-compatible aliases.
  static const String authLogin = AuthApiPaths.login;
  static const String authForgotPassword = AuthApiPaths.forgotPassword;
  static const String authPushToken = AuthApiPaths.pushToken;
  static const String authPushTokensMe = AuthApiPaths.pushTokensMe;
  static const String authFcmWebConfig = AuthApiPaths.fcmWebConfig;

  static const String userNotificationsPreferences =
      UserApiPaths.notificationsPreferences;

  static const String superadminRoles = SuperadminApiPaths.roles;
  static const String superadminRoleList = SuperadminApiPaths.roleList;
  static const String adminRoles = AdminApiPaths.roles;
  static const String adminRoleList = AdminApiPaths.roleList;

  static String superadminSupportTicketMessages(String ticketId) =>
      SuperadminApiPaths.supportTicketMessages(ticketId);
  static String superadminSupportTicketStatus(String ticketId) =>
      SuperadminApiPaths.supportTicketStatus(ticketId);
}

class AuthApiPaths {
  static const String prefix = '/auth';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String pushToken = '/auth/push-token';
  static const String pushTokensMe = '/auth/push-tokens/me';
  static const String fcmWebConfig = '/auth/fcm-web-config';
}

class PublicApiPaths {
  static const String prefix = '/';

  static String withSuffix(String suffix) => ApiPaths.path(suffix);

  static const String vehicleTypes = '/vehicletypes';
  static const String deviceTypes = '/devicestypes';
  static const String simProviders = '/simproviders';
  static const String documentTypesForUser = '/documenttypes/USER';
  static const String documentTypesForVehicle = '/documenttypes/VEHICLE';
  static const String languages = '/languages';
  static const String dateFormats = '/dateformats';
  static const String timezones = '/timezones';
  static const String mobilePrefix = '/mobileprefix';
  static const String policies = '/policies';

  static const String health = '/health';
  static const String healthDatabases = '/health/databases';
  static const String healthLogsDb = '/health/logs-db';
  static const String healthAddressDb = '/health/address-db';
}

class GeocodingApiPaths {
  static const String prefix = '/geocoding';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String reverse = '/geocoding/reverse';
}

class AdminApiPaths {
  static const String prefix = '/admin';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String roles = '/admin/roles';
  static const String roleList = '/admin/rolelist';

  static const String users = '/admin/users';
  static const String pricingPlans = '/admin/pricingplans';
  static const String quickDevice = '/admin/quickdevice';
  static const String mapTelemetry = '/admin/map-telemetry';

  static const String vehicles = '/admin/vehicles';
  static String vehicleDetails(String id) =>
      ApiPaths.path('/admin/vehicles/$id');
  static String vehicleConfig(String id) =>
      ApiPaths.path('/admin/vehicles/$id/config');
  static String vehicleByImeiDetails(String imei) =>
      ApiPaths.path('/admin/vehicles/by-imei/$imei/details');
  static String vehicleByImeiLogs(String imei) =>
      ApiPaths.path('/admin/vehicles/by-imei/$imei/logs');
  static String vehicleByImeiTrail(String imei) =>
      ApiPaths.path('/admin/vehicles/by-imei/$imei/trail');
  static String vehicleByImeiReplay(String imei) =>
      ApiPaths.path('/admin/vehicles/by-imei/$imei/replay');
  static String vehicleByImeiHistory(String imei) =>
      ApiPaths.path('/admin/vehicles/by-imei/$imei/history');

  static String linkUsers(String vehicleId) =>
      ApiPaths.path('/admin/linkusers/$vehicleId');

  static const String tickets = '/admin/tickets';
  static String ticketDetails(String ticketId) =>
      ApiPaths.path('/admin/tickets/$ticketId');
  static String ticketMessages(String ticketId) =>
      ApiPaths.path('/admin/tickets/$ticketId/messages');
  static String ticketStatus(String ticketId) =>
      ApiPaths.path('/admin/tickets/$ticketId/status');

  static const String myTickets = '/admin/mytickets';
  static String myTicketDetails(String ticketId) =>
      ApiPaths.path('/admin/mytickets/$ticketId');
  static String myTicketMessages(String ticketId) =>
      ApiPaths.path('/admin/mytickets/$ticketId/messages');
  static String myTicketStatus(String ticketId) =>
      ApiPaths.path('/admin/mytickets/$ticketId/status');
}

class UserApiPaths {
  static const String prefix = '/user';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String notificationsPreferences =
      '/user/notifications/preferences';

  static const String profile = '/user/profile';
  static const String updatePassword = '/user/updatepassword';

  static const String drivers = '/user/drivers';
  static String driverDetails(String id) => ApiPaths.path('/user/drivers/$id');

  static const String vehicles = '/user/vehicles';
  static String vehicleDetails(String id) =>
      ApiPaths.path('/user/vehicles/$id');
  static String vehicleDocuments(String id) =>
      ApiPaths.path('/user/vehicles/$id/documents');
  static String vehicleByImeiDetails(String imei) =>
      ApiPaths.path('/user/vehicles/by-imei/$imei/details');

  static const String mapTelemetry = '/user/map-telemetry';

  static const String tickets = '/user/tickets';
  static String ticketDetails(String ticketId) =>
      ApiPaths.path('/user/tickets/$ticketId');
}

class SuperadminApiPaths {
  static const String prefix = '/superadmin';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String roles = '/superadmin/roles';
  static const String roleList = '/superadmin/rolelist';

  static const String profile = '/superadmin/profile';
  static const String adminList = '/superadmin/adminlist';
  static String adminDetails(String id) =>
      ApiPaths.path('/superadmin/admin/$id');
  static String updateAdmin(String id) =>
      ApiPaths.path('/superadmin/updateadmin/$id');
  static String activateAdmin(String id) =>
      ApiPaths.path('/superadmin/activateadmin/$id');
  static const String adminStatusUpdate = '/superadmin/adminstatusupdate';
  static const String adminPasswordUpdate = '/superadmin/adminpasswordupdate';
  static String adminLogin(String id) =>
      ApiPaths.path('/superadmin/adminlogin/$id');

  static String upload(String id) => ApiPaths.path('/superadmin/upload/$id');
  static const String uploadDoc = '/superadmin/uploaddoc';
  static String uploadDocById(String id) =>
      ApiPaths.path('/superadmin/uploaddoc/$id');

  static String companyConfig(String companyId) =>
      ApiPaths.path('/superadmin/companyconfig/$companyId');
  static const String companyDetails = '/superadmin/companydetails';

  static const String createAdmin = '/superadmin/createadmin';
  static String deleteAdmin(String id) =>
      ApiPaths.path('/superadmin/deleteadmin/$id');

  static const String mapTelemetry = '/superadmin/map-telemetry';

  static const String vehicles = '/superadmin/vehicles';
  static String vehicleDetails(String id) =>
      ApiPaths.path('/superadmin/vehicles/$id');
  static String deleteVehicle(String id) =>
      ApiPaths.path('/superadmin/vehicles/$id');
  static String vehicleByImeiDetails(String imei) =>
      ApiPaths.path('/superadmin/vehicles/by-imei/$imei/details');
  static String vehicleByImeiLogs(String imei) =>
      ApiPaths.path('/superadmin/vehicles/by-imei/$imei/logs');

  static String adminVehicles(String adminId) =>
      ApiPaths.path('/superadmin/adminvehicles/$adminId');
  static String creditLogs(String adminId) =>
      ApiPaths.path('/superadmin/creditlogs/$adminId');
  static String documents(String adminId) =>
      ApiPaths.path('/superadmin/documents/$adminId');
  static String settings(String adminId) =>
      ApiPaths.path('/superadmin/settings/$adminId');

  static const String domainList = '/superadmin/domainlist';
  static const String serverOverview = '/superadmin/server/overview';
  static const String calendarEvents = '/superadmin/calendar/events';
  static const String calendarDay = '/superadmin/calendar/day';
  static const String localization = '/superadmin/localization';
  static const String smtpSettings = '/superadmin/smtpsettings';
  static const String testSmtp = '/superadmin/testsmtp';

  static const String commandTypes = '/superadmin/commandtypes';
  static const String customCommands = '/superadmin/customcommands';

  static const String supportTickets = '/superadmin/support/tickets';
  static String supportTicketDetails(String ticketId) =>
      ApiPaths.path('/superadmin/support/tickets/$ticketId');
  static String supportTicketMessages(String ticketId) =>
      ApiPaths.path('/superadmin/support/tickets/$ticketId/messages');
  static String supportTicketStatus(String ticketId) =>
      ApiPaths.path('/superadmin/support/tickets/$ticketId/status');

  static const String dashboardAdoptionGraph =
      '/superadmin/dashboard/adoptiongraph';
  static const String dashboardRecentVehicles =
      '/superadmin/dashboard/recentvehicles';
  static const String dashboardTotalCounts =
      '/superadmin/dashboard/totalcounts';
  static const String dashboardRecentUsers =
      '/superadmin/dashboard/recentusers';

  static const String transactions = '/superadmin/transactions';
  static const String transactionsManual = '/superadmin/transactions/manual';
}
