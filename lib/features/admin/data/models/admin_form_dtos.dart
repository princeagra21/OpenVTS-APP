import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';

class CreateAdminUserRequestDto {
  const CreateAdminUserRequestDto({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
    required this.companyName,
    required this.address,
    required this.countryCode,
    required this.stateCode,
    required this.city,
    required this.pincode,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;
  final String companyName;
  final String address;
  final String countryCode;
  final String stateCode;
  final String city;
  final String pincode;

  factory CreateAdminUserRequestDto.fromInput(CreateAdminUserInput input) {
    return CreateAdminUserRequestDto(
      name: input.name.trim(),
      email: input.email.trim(),
      mobilePrefix: input.mobilePrefix.trim(),
      mobileNumber: input.mobileNumber.trim(),
      username: input.username.trim(),
      password: input.password,
      companyName: input.companyName.trim(),
      address: input.address.trim(),
      countryCode: input.countryCode.trim(),
      stateCode: input.stateCode.trim(),
      city: input.city.trim(),
      pincode: input.pincode.trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'mobilePrefix': mobilePrefix,
        'mobileNumber': mobileNumber,
        'username': username,
        'password': password,
        'companyName': companyName,
        'address': address,
        'countryCode': countryCode,
        'stateCode': stateCode,
        'city': city,
        'pincode': pincode,
      };
}

class CreateAdminVehicleRequestDto {
  const CreateAdminVehicleRequestDto({
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.deviceId,
    required this.vehicleTypeId,
    required this.primaryUserId,
    required this.planId,
  });

  final String name;
  final String vin;
  final String plateNumber;
  final String deviceId;
  final String vehicleTypeId;
  final String primaryUserId;
  final String planId;

  factory CreateAdminVehicleRequestDto.fromInput(CreateAdminVehicleInput input) {
    return CreateAdminVehicleRequestDto(
      name: input.name.trim(),
      vin: input.vin.trim(),
      plateNumber: input.plateNumber.trim(),
      deviceId: input.deviceId.trim(),
      vehicleTypeId: input.vehicleTypeId.trim(),
      primaryUserId: input.primaryUserId.trim(),
      planId: input.planId.trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'vin': vin,
        'plateNumber': plateNumber,
        'deviceId': deviceId,
        'vehicleTypeId': vehicleTypeId,
        'primaryUserId': primaryUserId,
        'planId': planId,
      };
}

class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: _s(json['id'] ?? json['userId'] ?? json['uid']),
      name: _firstName(json),
      email: _s(json['email'] ?? json['emailAddress']),
    );
  }
}

class AdminVehicleDto {
  const AdminVehicleDto({
    required this.id,
    required this.name,
    required this.plateNumber,
  });

  final String id;
  final String name;
  final String plateNumber;

  factory AdminVehicleDto.fromJson(Map<String, dynamic> json) {
    return AdminVehicleDto(
      id: _s(json['id'] ?? json['vehicleId']),
      name: _s(json['name'] ?? json['vehicleName']),
      plateNumber: _s(json['plateNumber'] ?? json['registrationNumber'] ?? json['plateNo']),
    );
  }
}

class AdminFormUserOptionDto {
  const AdminFormUserOptionDto({required this.id, required this.fullName});
  final String id;
  final String fullName;

  factory AdminFormUserOptionDto.fromJson(Map<String, dynamic> json) {
    return AdminFormUserOptionDto(
      id: _s(json['id'] ?? json['userId'] ?? json['uid']),
      fullName: _firstName(json),
    );
  }
}

class AdminQuickDeviceDto {
  const AdminQuickDeviceDto({required this.id, required this.imei});
  final String id;
  final String imei;

  factory AdminQuickDeviceDto.fromJson(Map<String, dynamic> json) {
    return AdminQuickDeviceDto(
      id: _s(json['id'] ?? json['deviceId']),
      imei: _s(json['imei'] ?? json['deviceImei']),
    );
  }
}

class AdminVehicleTypeDto {
  const AdminVehicleTypeDto({required this.id, required this.name});
  final String id;
  final String name;

  factory AdminVehicleTypeDto.fromJson(Map<String, dynamic> json) {
    return AdminVehicleTypeDto(
      id: _s(json['id'] ?? json['value'] ?? json['code']),
      name: _s(json['name'] ?? json['label'] ?? json['title']),
    );
  }
}

class AdminPricingPlanDto {
  const AdminPricingPlanDto({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });

  final String id;
  final String name;
  final double price;
  final String currency;

  factory AdminPricingPlanDto.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price'];
    return AdminPricingPlanDto(
      id: _s(json['id'] ?? json['planId']),
      name: _s(json['name'] ?? json['title']),
      price: priceRaw is num ? priceRaw.toDouble() : double.tryParse(_s(priceRaw)) ?? 0,
      currency: _s(json['currency'] ?? json['currencyCode']),
    );
  }
}

String _s(Object? value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text.toLowerCase() == 'null' ? '' : text;
}

String _firstName(Map<String, dynamic> json) {
  final explicit = _s(json['fullName'] ?? json['name']);
  if (explicit.isNotEmpty) return explicit;
  final first = _s(json['firstName']);
  final last = _s(json['lastName']);
  final merged = '$first $last'.trim();
  if (merged.isNotEmpty) return merged;
  return _s(json['username'] ?? json['email']);
}
