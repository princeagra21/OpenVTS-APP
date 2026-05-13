import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';

class UserVehicleTypeDto {
  const UserVehicleTypeDto(this.raw);

  final Map<String, dynamic> raw;

  factory UserVehicleTypeDto.fromJson(Map<String, dynamic> json) => UserVehicleTypeDto(json);
}

class CreateUserVehicleRequestDto {
  const CreateUserVehicleRequestDto(this.payload);

  final Map<String, Object?> payload;

  factory CreateUserVehicleRequestDto.fromInput(CreateUserVehicleInput input) {
    return CreateUserVehicleRequestDto(input.toPayload());
  }

  Map<String, Object?> toJson() => payload;
}
