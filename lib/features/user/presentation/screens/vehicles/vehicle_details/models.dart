enum VehicleDetailsTab {
  details,
  documents,
  config,
}

extension VehicleDetailsTabX on VehicleDetailsTab {
  String get label {
    switch (this) {
      case VehicleDetailsTab.details:
        return 'Vehicle Details';
      case VehicleDetailsTab.documents:
        return 'Documents';
      case VehicleDetailsTab.config:
        return 'Config';
    }
  }

  static VehicleDetailsTab fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'documents') return VehicleDetailsTab.documents;
    if (normalized == 'config') return VehicleDetailsTab.config;
    return VehicleDetailsTab.details;
  }
}

class VehicleDetailsActionResult {
  const VehicleDetailsActionResult({required this.message, this.isError = false});

  final String message;
  final bool isError;

  static VehicleDetailsActionResult success(String message) {
    return VehicleDetailsActionResult(message: message);
  }

  static VehicleDetailsActionResult error(String message) {
    return VehicleDetailsActionResult(message: message, isError: true);
  }
}
