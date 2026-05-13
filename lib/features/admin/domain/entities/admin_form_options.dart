class AdminFormUserOption {
  const AdminFormUserOption({required this.id, required this.fullName});

  final String id;
  final String fullName;
}

class AdminFormQuickDeviceOption {
  const AdminFormQuickDeviceOption({required this.id, required this.imei});

  final String id;
  final String imei;
}

class AdminFormVehicleTypeOption {
  const AdminFormVehicleTypeOption({required this.id, required this.name});

  final String id;
  final String name;
}

class AdminFormPlanOption {
  const AdminFormPlanOption({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
}

class AdminCreatedUser {
  const AdminCreatedUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

class AdminCreatedVehicle {
  const AdminCreatedVehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
  });

  final String id;
  final String name;
  final String plateNumber;
}
