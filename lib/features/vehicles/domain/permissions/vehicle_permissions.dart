enum VehicleRole { superadmin, admin, user }

/// Permissions for vehicle operations based on role.
class VehiclePermissions {
  const VehiclePermissions({
    this.canViewAllVehicles = false,
    this.canViewTelemetry = false,
    this.canEditVehicles = false,
    this.canDeleteVehicles = false,
    this.canSendCommands = false,
    this.canViewDocuments = false,
    this.canExportData = false,
    this.canToggleActive = false,
  });

  final bool canViewAllVehicles;
  final bool canViewTelemetry;
  final bool canEditVehicles;
  final bool canDeleteVehicles;
  final bool canSendCommands;
  final bool canViewDocuments;
  final bool canExportData;
  final bool canToggleActive;

  static const VehiclePermissions superadmin = VehiclePermissions(
    canViewAllVehicles: true,
    canViewTelemetry: true,
    canEditVehicles: true,
    canDeleteVehicles: true,
    canSendCommands: true,
    canViewDocuments: true,
    canExportData: true,
    canToggleActive: true,
  );

  static const VehiclePermissions admin = VehiclePermissions(
    canViewAllVehicles: true,
    canViewTelemetry: true,
    canEditVehicles: true,
    canDeleteVehicles: false,
    canSendCommands: true,
    canViewDocuments: true,
    canExportData: true,
    canToggleActive: true,
  );

  static const VehiclePermissions user = VehiclePermissions(
    canViewAllVehicles: false,
    canViewTelemetry: true,
    canEditVehicles: false,
    canDeleteVehicles: false,
    canSendCommands: false,
    canViewDocuments: false,
    canExportData: false,
    canToggleActive: false,
  );
}

/// Actions available for vehicles.
enum VehicleAction {
  viewDetails,
  edit,
  delete,
  sendCommand,
  toggleActive,
  viewDocuments,
  export,
}

extension VehicleActionLabels on VehicleAction {
  String get label {
    switch (this) {
      case VehicleAction.viewDetails:
        return 'View Details';
      case VehicleAction.edit:
        return 'Edit';
      case VehicleAction.delete:
        return 'Delete';
      case VehicleAction.sendCommand:
        return 'Send Command';
      case VehicleAction.toggleActive:
        return 'Toggle Active';
      case VehicleAction.viewDocuments:
        return 'View Documents';
      case VehicleAction.export:
        return 'Export';
    }
  }
}
