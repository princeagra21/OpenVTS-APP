/// Unified vehicle item model for shared vehicle feature
class VehicleItem {
  final Map<String, dynamic> raw;

  const VehicleItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['uid'] ??
        raw['_id'] ??
        raw['uuid'],
  );

  String get name => _string(
    raw['name'] ??
        raw['vehicleName'] ??
        raw['title'] ??
        raw['model'] ??
        raw['plateNumber'],
  );

  String get plateNumber => _string(
    raw['plateNumber'] ??
        raw['plate'] ??
        raw['registrationNumber'] ??
        raw['registrationNo'],
  );

  String get vin => _string(
    raw['vin'] ??
        raw['VIN'] ??
        raw['chassisNumber'] ??
        raw['chassisNo'] ??
        raw['vehicleVin'],
  );

  String get imei => _string(
    raw['imei'] ??
        raw['deviceImei'] ??
        raw['device_imei'] ??
        raw['imeiNumber'] ??
        (raw['device'] is Map ? raw['device']['imei'] : null) ??
        (raw['device'] is Map ? raw['device']['imeiNumber'] : null),
  );

  String get simNumber => _string(
    raw['simNumber'] ??
        raw['sim_number'] ??
        raw['simNo'] ??
        raw['sim'],
  );

  String get type => _string(
    raw['type'] ??
        raw['vehicleType'] ??
        raw['vehicleTypeName'] ??
        raw['vehicle_type_name'] ??
        (raw['vehicleType'] is Map ? raw['vehicleType']['name'] : null) ??
        (raw['vehicleType'] is Map ? raw['vehicleType']['title'] : null),
  );

  String get status => _string(
    raw['status'] ??
        raw['state'] ??
        raw['vehicleStatus'] ??
        raw['liveStatus'],
  );

  String get motion => _string(
    raw['motion'] ??
        raw['movement'] ??
        raw['movementStatus'] ??
        raw['status'] ??
        raw['state'],
  );

  String get speed => _string(
    raw['speed'] ??
        raw['speedKph'] ??
        raw['currentSpeed'],
  );

  String get engine => _string(
    raw['engine'] ??
        raw['engineStatus'] ??
        raw['ignition'] ??
        raw['ignitionStatus'],
  );

  String get driverName => _string(
    raw['driverName'] ??
        raw['driver'] ??
        (raw['primaryUser'] is Map ? raw['primaryUser']['name'] : null) ??
        (raw['userPrimary'] is Map ? raw['userPrimary']['name'] : null) ??
        raw['primaryUserName'] ??
        raw['primary_user_name'],
  );

  String get userPrimaryName => _string(
    (raw['userPrimary'] is Map
            ? (raw['userPrimary'] as Map)['name'] ??
                  (raw['userPrimary'] as Map)['fullName']
            : null) ??
        raw['primaryUserName'] ??
        raw['primary_user_name'] ??
        driverName,
  );

  String get userAddedByName => _string(
    (raw['userAddedBy'] is Map
            ? (raw['userAddedBy'] as Map)['name'] ??
                  (raw['userAddedBy'] as Map)['fullName'] ??
                  (raw['userAddedBy'] as Map)['username']
            : null) ??
        raw['addedByName'] ??
        raw['added_by_name'],
  );

  String get createdAt => _string(raw['createdAt'] ?? raw['created_at']);
  String get updatedAt => _string(raw['updatedAt'] ?? raw['updated_at']);

  bool get isActive => raw['isActive'] == true || raw['active'] == true;

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

/// Vehicle list state for shared controller
class VehicleListState {
  const VehicleListState({
    this.items = const [],
    this.loading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedTab = 'All',
  });

  final List<VehicleItem> items;
  final bool loading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedTab;

  VehicleListState copyWith({
    List<VehicleItem>? items,
    bool? loading,
    String? errorMessage,
    String? searchQuery,
    String? selectedTab,
  }) {
    return VehicleListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}