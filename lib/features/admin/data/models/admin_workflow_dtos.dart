import 'package:open_vts/features/admin/domain/entities/admin_device_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';

class AdminAssignableUserDto {
  const AdminAssignableUserDto(this.raw);

  final Map<String, dynamic> raw;

  factory AdminAssignableUserDto.fromJson(Map<String, dynamic> json) {
    return AdminAssignableUserDto(json);
  }
}

class AdminDriverDto {
  const AdminDriverDto(this.raw);

  final Map<String, dynamic> raw;

  factory AdminDriverDto.fromJson(Map<String, dynamic> json) {
    return AdminDriverDto(json);
  }
}

class AdminDeviceTypeDto {
  const AdminDeviceTypeDto(this.raw);

  final Map<String, dynamic> raw;

  factory AdminDeviceTypeDto.fromJson(Map<String, dynamic> json) {
    return AdminDeviceTypeDto(json);
  }
}

class AdminSimDto {
  const AdminSimDto(this.raw);

  final Map<String, dynamic> raw;

  factory AdminSimDto.fromJson(Map<String, dynamic> json) {
    return AdminSimDto(json);
  }
}

class CreateAdminDriverRequestDto {
  const CreateAdminDriverRequestDto(this.payload);

  final Map<String, Object?> payload;

  factory CreateAdminDriverRequestDto.fromInput(CreateAdminDriverInput input) {
    return CreateAdminDriverRequestDto(input.toPayload());
  }

  Map<String, Object?> toJson() => payload;
}

class CreateAdminDeviceRequestDto {
  const CreateAdminDeviceRequestDto({
    required this.imei,
    required this.deviceTypeId,
    this.simId,
  });

  final String imei;
  final String deviceTypeId;
  final String? simId;

  factory CreateAdminDeviceRequestDto.fromInput(CreateAdminDeviceInput input) {
    return CreateAdminDeviceRequestDto(
      imei: input.imei,
      deviceTypeId: input.deviceTypeId,
      simId: input.simId,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'imei': imei.trim(),
        'deviceTypeId': _numOrString(deviceTypeId.trim()),
        if ((simId ?? '').trim().isNotEmpty) 'simId': _numOrString(simId!.trim()),
      };
}

class CreateAdminTeamRequestDto {
  const CreateAdminTeamRequestDto({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;

  factory CreateAdminTeamRequestDto.fromInput(CreateAdminTeamInput input) {
    return CreateAdminTeamRequestDto(
      name: input.name,
      email: input.email,
      mobilePrefix: input.mobilePrefix,
      mobileNumber: input.mobileNumber,
      username: input.username,
      password: input.password,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name.trim(),
        'email': email.trim(),
        'mobilePrefix': mobilePrefix.trim(),
        'mobileNumber': mobileNumber.trim(),
        'username': username.trim(),
        'password': password,
      };
}

Object _numOrString(String raw) {
  return int.tryParse(raw) ?? raw;
}
