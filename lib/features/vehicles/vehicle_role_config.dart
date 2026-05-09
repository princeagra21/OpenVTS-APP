import 'package:open_vts/features/vehicles/vehicle_permissions.dart';

/// Configuration for vehicle features based on role
class VehicleRoleConfig {
  const VehicleRoleConfig({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.permissions,
    required this.availableTabs,
    required this.listEndpoint,
    required this.detailsEndpoint,
    required this.routeBuilder,
    this.telemetryEndpoint,
    this.commandEndpoint,
  });

  final VehicleRole role;
  final String title;
  final String subtitle;
  final VehiclePermissions permissions;
  final List<String> availableTabs;
  final String listEndpoint;
  final String detailsEndpoint;
  final String Function(String vehicleId) routeBuilder;
  final String? telemetryEndpoint;
  final String? commandEndpoint;

  static VehicleRoleConfig get superadmin => const VehicleRoleConfig(
    role: VehicleRole.superadmin,
    title: 'Vehicle Management',
    subtitle: 'Manage all vehicles in the system',
    permissions: VehiclePermissions.superadmin,
    availableTabs: ['All', 'Active', 'Inactive'],
    listEndpoint: '/superadmin/vehicles',
    detailsEndpoint: '/superadmin/vehicles',
    routeBuilder: _superadminRouteBuilder,
    telemetryEndpoint: '/superadmin/map-telemetry',
    commandEndpoint: '/superadmin/vehicles/commands',
  );

  static VehicleRoleConfig get admin => const VehicleRoleConfig(
    role: VehicleRole.admin,
    title: 'My Vehicles',
    subtitle: 'Manage vehicles assigned to your organization',
    permissions: VehiclePermissions.admin,
    availableTabs: ['All', 'Running', 'Stopped'],
    listEndpoint: '/admin/vehicles',
    detailsEndpoint: '/admin/vehicles',
    routeBuilder: _adminRouteBuilder,
    telemetryEndpoint: '/admin/map-telemetry',
    commandEndpoint: '/admin/vehicles/commands',
  );

  static VehicleRoleConfig get user => const VehicleRoleConfig(
    role: VehicleRole.user,
    title: 'My Vehicles',
    subtitle: 'View vehicles assigned to you',
    permissions: VehiclePermissions.user,
    availableTabs: ['All'],
    listEndpoint: '/user/vehicles',
    detailsEndpoint: '/user/vehicles',
    routeBuilder: _userRouteBuilder,
  );

  static VehicleRoleConfig fromRole(VehicleRole role) {
    switch (role) {
      case VehicleRole.superadmin:
        return superadmin;
      case VehicleRole.admin:
        return admin;
      case VehicleRole.user:
        return user;
    }
  }

  static String _superadminRouteBuilder(String vehicleId) => '/superadmin/vehicles/$vehicleId';
  static String _adminRouteBuilder(String vehicleId) => '/admin/vehicles/$vehicleId';
  static String _userRouteBuilder(String vehicleId) => '/user/vehicles/$vehicleId';
}

/// Vehicle list request parameters
class VehicleListRequest {
  const VehicleListRequest({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 100,
  });

  final String? search;
  final String? status;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParams() {
    return {
      if (search != null && search!.isNotEmpty) 'search': search,
      if (status != null && status!.isNotEmpty) 'status': status,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}

/// Vehicle details request parameters
class VehicleDetailsRequest {
  const VehicleDetailsRequest({
    required this.vehicleId,
    this.includeTelemetry = false,
  });

  final String vehicleId;
  final bool includeTelemetry;
}