class VehicleDetailsConfig {
  static const List<String> tabs = <String>[
    'Vehicle Details',
    'Documents',
    'Config',
  ];

  static const List<String> documentFilters = <String>[
    'All',
    'Valid',
    'Warning',
    'Expired',
  ];

  static const List<int> documentPageSizes = <int>[10, 25, 50];

  static const double minMultiplier = 0.1;
  static const double maxMultiplier = 10.0;
  static const double maxOdometer = 1000000.0;
  static const double maxEngineHours = 100000.0;
}
