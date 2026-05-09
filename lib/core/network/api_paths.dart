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
  static const String refreshToken = '/auth/refresh';
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
  static const String countries = '/countries';
  static const String currencies = '/currencies';
  static const String mobilePrefix = '/mobileprefix';
  static const String policies = '/policies';

  static String states(String countryId) => ApiPaths.path('/states/$countryId');

  // Backend currently supports /cities/{countryId}/{stateId}; keep this as source of truth.
  static String cities(String stateId, {String? countryId}) {
    if (countryId == null || countryId.trim().isEmpty) {
      return ApiPaths.path('/cities/$stateId');
    }
    return ApiPaths.path('/cities/$countryId/$stateId');
  }

  static String citiesForCountryState(String countryId, String stateId) =>
      cities(stateId, countryId: countryId);

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
  static String userDetails(String userId) =>
      ApiPaths.path('/admin/users/$userId');
  static String userLogin(String userId) =>
      ApiPaths.path('/admin/userlogin/$userId');
  static String userActivityLogs(String userId) =>
      ApiPaths.path('/admin/users/$userId/activitylogs');
  static String userUnlinkedDrivers(String userId) =>
      ApiPaths.path('/admin/users/unlinkeddrivers/$userId');

  static String linkVehicles(String userId) =>
      ApiPaths.path('/admin/linkvehicles/$userId');
  static const String linkVehiclesBase = '/admin/linkvehicles';

  static const String unlinkVehicles = '/admin/unlinkvehicles';
  static String unlinkVehiclesByUser(String userId) =>
      ApiPaths.path('/admin/unlinkvehicles/$userId');

  static String linkUsers(String vehicleId) =>
      ApiPaths.path('/admin/linkusers/$vehicleId');

  static String documents(String userId) =>
      ApiPaths.path('/admin/documents/$userId');

  static const String uploadDoc = '/admin/uploaddoc';
  static String uploadDocById(String documentId) =>
      ApiPaths.path('/admin/uploaddoc/$documentId');

  static const String payments = '/admin/payments';
  static const String paymentsRenew = '/admin/payments/renew';

  static String updateUserPassword(String userId) =>
      ApiPaths.path('/admin/updateuserpassword/$userId');

  static const String profile = '/admin/profile';
  static const String updatePassword = '/admin/updatepassword';
  static const String profileVerifyEmailRequest =
      '/admin/profile/verify/email/request';
  static const String profileVerifyEmailConfirm =
      '/admin/profile/verify/email/confirm';
  static const String profileVerifyWhatsappRequest =
      '/admin/profile/verify/whatsapp/request';
  static const String profileVerifyWhatsappConfirm =
      '/admin/profile/verify/whatsapp/confirm';

  static String companyDetails(String id) =>
      ApiPaths.path('/admin/companydetails/$id');

  static const String upload = '/admin/upload';

  static const String pricingPlans = '/admin/pricingplans';
  static String pricingPlanDetails(String id) =>
      ApiPaths.path('/admin/pricingplans/$id');

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

  static const String drivers = '/admin/drivers';
  static String driverDetails(String driverId) =>
      ApiPaths.path('/admin/drivers/$driverId');
  static String driverDocuments(String driverId) =>
      ApiPaths.path('/admin/documents/driver/$driverId');
  static String driverLinkedUsers(String driverId) =>
      ApiPaths.path('/admin/drivers/linkedusers/$driverId');
  static String driverUnlinkedUsers(String driverId) =>
      ApiPaths.path('/admin/drivers/unlinkedusers/$driverId');

  static const String teams = '/admin/teams';
  static String teamDetails(String teamId) =>
      ApiPaths.path('/admin/teams/$teamId');

  static const String devices = '/admin/devices';
  static String deviceDetails(String deviceId) =>
      ApiPaths.path('/admin/devices/$deviceId');
  static const String deviceAndSim = '/admin/deviceandsim';

  static const String simcards = '/admin/simcards';
  static String simcardDetails(String simId) =>
      ApiPaths.path('/admin/simcards/$simId');
  static const String quickSimcards = '/admin/quicksimcards';

  static const String localization = '/admin/localization';
  static const String config = '/admin/config';

  static const String transactions = '/admin/transactions';
  static const String transactionsAnalytics = '/admin/transactions/analytics';

  static const String dashboardSummary = '/admin/dashboard/summary';

  static const String calendarEvents = '/admin/calendar/events';
  static String calendarUser(String userId) =>
      ApiPaths.path('/admin/calendar/user/$userId');
  static const String calendarDay = '/admin/calendar/day';

  static const String logsOptions = '/admin/logs/options';
  static const String logsActivity = '/admin/logs/activity';
  static const String logsEvents = '/admin/logs/events';

  static const String notifications = '/admin/notifications';
  static String notificationRead(String id) =>
      ApiPaths.path('/admin/notifications/$id/read');
  static const String notificationsReadAll = '/admin/notifications/read-all';

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

  static const String profileVerifyEmailRequest =
      '/user/profile/verify/email/request';
  static const String profileVerifyEmailConfirm =
      '/user/profile/verify/email/confirm';
  static const String profileVerifyWhatsappRequest =
      '/user/profile/verify/whatsapp/request';
  static const String profileVerifyWhatsappConfirm =
      '/user/profile/verify/whatsapp/confirm';

  static const String drivers = '/user/drivers';
  static String driverDetails(String id) => ApiPaths.path('/user/drivers/$id');

  static const String vehicles = '/user/vehicles';
  static String vehicleDetails(String id) =>
      ApiPaths.path('/user/vehicles/$id');
  static String vehicleDocuments(String id) =>
      ApiPaths.path('/user/vehicles/$id/documents');
  static String vehicleConfig(String vehicleId) =>
      ApiPaths.path('/user/vehicles/$vehicleId/config');
  static String vehicleByImeiDetails(String imei) =>
      ApiPaths.path('/user/vehicles/by-imei/$imei/details');
  static String vehicleByImeiTrail(String imei) =>
      ApiPaths.path('/user/vehicles/by-imei/$imei/trail');
  static String vehicleByImeiReplay(String imei) =>
      ApiPaths.path('/user/vehicles/by-imei/$imei/replay');
  static String vehicleByImeiHistory(String imei) =>
      ApiPaths.path('/user/vehicles/by-imei/$imei/history');

  static const String mapTelemetry = '/user/map-telemetry';

  static const String routes = '/user/routes';
  static String routeDetails(String id) => ApiPaths.path('/user/routes/$id');

  static const String geofences = '/user/geofences';
  static const String pois = '/user/pois';
  static const String localization = '/user/localization';

  static const String subusers = '/user/subusers';
  static String subuserDetails(String id) =>
      ApiPaths.path('/user/subusers/$id');
  static String subuserVehicles(String id) =>
      ApiPaths.path('/user/subusers/$id/vehicles');
  static String subuserVehiclesAssign(String id) =>
      ApiPaths.path('/user/subusers/$id/vehicles/assign');
  static String subuserVehiclesUnassign(String id) =>
      ApiPaths.path('/user/subusers/$id/vehicles/unassign');

  static const String shareTrackLinks = '/user/sharetracklinks';
  static String shareTrackLinkDetails(String id) =>
      ApiPaths.path('/user/sharetracklinks/$id');

  static const String tickets = '/user/tickets';
  static String ticketDetails(String ticketId) =>
      ApiPaths.path('/user/tickets/$ticketId');

  static const String transactions = '/user/transactions';

  static const String dashboardFleetStatus = '/user/dashboard/fleet-status';
  static const String dashboardUsageLast7Days =
      '/user/dashboard/usage-last-7-days';
  static const String dashboardRecentAlerts = '/user/dashboard/recent-alerts';
  static const String dashboardTopPerformingAssets =
      '/user/dashboard/top-performing-assets';
}

class SuperadminApiPaths {
  static const String prefix = '/superadmin';

  static String withSuffix(String suffix) => ApiPaths.path('$prefix/$suffix');

  static const String roles = '/superadmin/roles';
  static const String roleList = '/superadmin/rolelist';

  static const String profile = '/superadmin/profile';
  static const String profileVerifyEmailRequest =
      '/superadmin/profile/verify/email/request';
  static const String profileVerifyWhatsappRequest =
      '/superadmin/profile/verify/whatsapp/request';

  static const String whiteLabel = '/superadmin/whitelabel';
  static const String softwareConfig = '/superadmin/softwareconfig';
  static const String policy = '/superadmin/policy';

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
  static String adminActivityLogs(String id) =>
      ApiPaths.path('/superadmin/admin/$id/activitylogs');

  static String assignCredits(String adminId) =>
      ApiPaths.path('/superadmin/assigncredits/$adminId');

  static String uploadById(String id) =>
      ApiPaths.path('/superadmin/upload/$id');
  static String upload(String id) => uploadById(id);

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
