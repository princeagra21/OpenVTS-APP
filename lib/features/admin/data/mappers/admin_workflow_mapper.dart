import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_workflow_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';

class AdminWorkflowMapper {
  const AdminWorkflowMapper();

  List<AdminAssignableUserDto> usersFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['userslist', 'users'],
    ).map(_userDto).toList(growable: false);
  }

  AdminDriverDto? createdDriverFromResponse(Object? raw) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      raw,
      preferredKeys: const <String>['driver', 'item'],
    );
    return map.isEmpty ? null : AdminDriverDto.fromJson(map);
  }

  List<AdminDeviceTypeDto> deviceTypesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['devicetypes', 'deviceTypes', 'types'],
    ).map(_deviceTypeDto).toList(growable: false);
  }

  List<AdminSimDto> simsFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['simcards', 'sims'],
    ).map(_simDto).toList(growable: false);
  }

  AdminUserListItem user(AdminAssignableUserDto dto) => AdminUserListItem.fromRaw(dto.raw);

  AdminDriverListItem driver(AdminDriverDto dto) => AdminDriverListItem.fromRaw(dto.raw);

  DeviceTypeOption deviceType(AdminDeviceTypeDto dto) => DeviceTypeOption.fromRaw(dto.raw);

  SimOption sim(AdminSimDto dto) => SimOption.fromRaw(dto.raw);

  AdminDeviceFormData deviceFormData({
    required List<AdminDeviceTypeDto> deviceTypes,
    required List<AdminSimDto> sims,
  }) {
    return AdminDeviceFormData(
      deviceTypes: deviceTypes.map(deviceType).where((e) => e.id.isNotEmpty && e.name.isNotEmpty).toList(),
      sims: sims.map(sim).where((e) => e.id.isNotEmpty || e.label.isNotEmpty).toList(),
    );
  }

  AdminAssignableUserDto _userDto(Object? value) {
    if (value is AdminAssignableUserDto) return value;
    return AdminAssignableUserDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  AdminDeviceTypeDto _deviceTypeDto(Object? value) {
    if (value is AdminDeviceTypeDto) return value;
    return AdminDeviceTypeDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  AdminSimDto _simDto(Object? value) {
    if (value is AdminSimDto) return value;
    return AdminSimDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }
}
