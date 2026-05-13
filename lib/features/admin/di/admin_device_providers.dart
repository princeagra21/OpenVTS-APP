import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_device_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_device_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_device_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_device_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_device_detail_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_devices_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_sim_card_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/load_admin_device_references_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_device_use_case.dart';

final adminDeviceApiServiceProvider = Provider<AdminDeviceApiService>((ref) {
  return AdminDeviceApiService(ref.watch(appDioProvider));
});

final adminDeviceMapperProvider = Provider<AdminDeviceMapper>((ref) => const AdminDeviceMapper());

final adminDeviceRepositoryProvider = Provider<AdminDeviceRepository>((ref) {
  return AdminDeviceRepositoryImpl(
    api: ref.watch(adminDeviceApiServiceProvider),
    mapper: ref.watch(adminDeviceMapperProvider),
  );
});

final getAdminDevicesUseCaseProvider = Provider<GetAdminDevicesUseCase>((ref) {
  return GetAdminDevicesUseCase(ref.watch(adminDeviceRepositoryProvider));
});

final getAdminDeviceDetailUseCaseProvider = Provider<GetAdminDeviceDetailUseCase>((ref) {
  return GetAdminDeviceDetailUseCase(ref.watch(adminDeviceRepositoryProvider));
});

final createAdminDeviceUseCaseProvider = Provider<CreateAdminDeviceUseCase>((ref) {
  return CreateAdminDeviceUseCase(ref.watch(adminDeviceRepositoryProvider));
});

final createAdminDeviceAndSimUseCaseProvider = Provider<CreateAdminDeviceAndSimUseCase>((ref) {
  return CreateAdminDeviceAndSimUseCase(ref.watch(adminDeviceRepositoryProvider));
});

final updateAdminDeviceUseCaseProvider = Provider<UpdateAdminDeviceUseCase>((ref) {
  return UpdateAdminDeviceUseCase(ref.watch(adminDeviceRepositoryProvider));
});


final createAdminSimCardUseCaseProvider = Provider<CreateAdminSimCardUseCase>((ref) {
  return CreateAdminSimCardUseCase(ref.watch(adminDeviceRepositoryProvider));
});

final loadAdminDeviceReferencesUseCaseProvider = Provider<LoadAdminDeviceReferencesUseCase>((ref) {
  return LoadAdminDeviceReferencesUseCase(ref.watch(adminDeviceRepositoryProvider));
});
