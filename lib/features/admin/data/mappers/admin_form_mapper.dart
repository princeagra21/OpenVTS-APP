import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_form_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';

class AdminFormMapper {
  const AdminFormMapper();

  List<AdminFormUserOptionDto> usersFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['userslist', 'users'],
    ).map(_userDto).toList(growable: false);
  }

  List<AdminQuickDeviceDto> quickDevicesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['devices', 'quickDevices'],
    ).map(_quickDeviceDto).toList(growable: false);
  }

  List<AdminVehicleTypeDto> vehicleTypesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['types', 'vehicleTypes'],
    ).map(_vehicleTypeDto).toList(growable: false);
  }

  List<AdminPricingPlanDto> pricingPlansFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['plans', 'pricingPlans'],
    ).map(_pricingPlanDto).toList(growable: false);
  }

  AdminUserDto? createdUserFromResponse(Object? raw) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      raw,
      preferredKeys: const <String>['user', 'item'],
    );
    return map.isEmpty ? null : AdminUserDto.fromJson(map);
  }

  AdminVehicleDto? createdVehicleFromResponse(Object? raw) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      raw,
      preferredKeys: const <String>['vehicle', 'item'],
    );
    return map.isEmpty ? null : AdminVehicleDto.fromJson(map);
  }

  AdminFormUserOption user(AdminFormUserOptionDto dto) => AdminFormUserOption(
        id: dto.id,
        fullName: dto.fullName,
      );

  AdminFormQuickDeviceOption quickDevice(AdminQuickDeviceDto dto) => AdminFormQuickDeviceOption(
        id: dto.id,
        imei: dto.imei,
      );

  AdminFormVehicleTypeOption vehicleType(AdminVehicleTypeDto dto) => AdminFormVehicleTypeOption(
        id: dto.id,
        name: dto.name,
      );

  AdminFormPlanOption pricingPlan(AdminPricingPlanDto dto) => AdminFormPlanOption(
        id: dto.id,
        name: dto.name,
        price: dto.price,
        currency: dto.currency,
      );

  AdminCreatedUser createdUser(AdminUserDto dto) => AdminCreatedUser(
        id: dto.id,
        name: dto.name,
        email: dto.email,
      );

  AdminCreatedVehicle createdVehicle(AdminVehicleDto dto) => AdminCreatedVehicle(
        id: dto.id,
        name: dto.name,
        plateNumber: dto.plateNumber,
      );

  AdminFormUserOptionDto _userDto(Object? value) {
    if (value is AdminFormUserOptionDto) return value;
    return AdminFormUserOptionDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  AdminQuickDeviceDto _quickDeviceDto(Object? value) {
    if (value is AdminQuickDeviceDto) return value;
    return AdminQuickDeviceDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  AdminVehicleTypeDto _vehicleTypeDto(Object? value) {
    if (value is AdminVehicleTypeDto) return value;
    return AdminVehicleTypeDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  AdminPricingPlanDto _pricingPlanDto(Object? value) {
    if (value is AdminPricingPlanDto) return value;
    return AdminPricingPlanDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }
}
