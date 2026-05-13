import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

abstract interface class AdminDeviceRepository {
  Future<Result<List<AdminDeviceListItem>, AppError>> getDevices({
    String? search,
    String? status,
    int? page,
    int? limit,
  });

  Future<Result<AdminDeviceListItem, AppError>> getDeviceDetail(String deviceId);

  Future<Result<List<DeviceTypeOption>, AppError>> getDeviceTypes();

  Future<Result<List<SimOption>, AppError>> getSims();

  Future<Result<List<SimProviderOption>, AppError>> getSimProviders();

  Future<Result<List<SimOption>, AppError>> getQuickSimCards();

  Future<Result<void, AppError>> createSimCard(CreateAdminSimCardMutationInput input);

  Future<Result<void, AppError>> createDevice(CreateAdminDeviceMutationInput input);

  Future<Result<void, AppError>> createDeviceAndSim(CreateAdminDeviceAndSimMutationInput input);

  Future<Result<void, AppError>> updateDevice(String deviceId, UpdateAdminDeviceMutationInput input);

  Future<Result<void, AppError>> updateDeviceStatus(String deviceId, bool isActive);
}
