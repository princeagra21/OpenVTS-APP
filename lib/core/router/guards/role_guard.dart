import 'package:open_vts/features/auth/domain/entities/user_role.dart';

enum Permission {
  viewVehicles,
  createVehicles,
  editVehicles,
  deleteVehicles,
  viewDrivers,
  createDrivers,
  viewInventory,
  manageUsers,
  managePricing,
  viewPayments,
  manageAdmins,
  viewServerConfig,
  viewMasterData,
  impersonateAdmin,
  viewReports,
  manageSettings,
  viewSupport,
}

abstract class RolePermissions {
  static const Map<UserRole, Set<Permission>> _permissions = {
    UserRole.superadmin: {
      Permission.viewVehicles,
      Permission.viewDrivers,
      Permission.viewPayments,
      Permission.manageAdmins,
      Permission.viewServerConfig,
      Permission.viewMasterData,
      Permission.impersonateAdmin,
      Permission.viewReports,
      Permission.manageSettings,
      Permission.viewSupport,
    },
    UserRole.admin: {
      Permission.viewVehicles,
      Permission.createVehicles,
      Permission.editVehicles,
      Permission.deleteVehicles,
      Permission.viewDrivers,
      Permission.createDrivers,
      Permission.viewInventory,
      Permission.manageUsers,
      Permission.managePricing,
      Permission.viewPayments,
      Permission.viewReports,
      Permission.manageSettings,
      Permission.viewSupport,
    },
    UserRole.user: {
      Permission.viewVehicles,
      Permission.viewDrivers,
      Permission.viewPayments,
      Permission.viewSupport,
    },
    UserRole.subuser: {
      Permission.viewVehicles,
      Permission.viewSupport,
    },
    UserRole.team: {
      Permission.viewVehicles,
      Permission.viewDrivers,
      Permission.viewSupport,
    },
    UserRole.driver: {
      Permission.viewVehicles,
    },
    UserRole.unknown: <Permission>{},
  };

  static bool can(UserRole? role, Permission permission) {
    if (role == null) return false;
    return _permissions[role]?.contains(permission) ?? false;
  }
}
