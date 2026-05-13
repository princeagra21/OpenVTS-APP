import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/database/database_providers.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/storage/cache_keys.dart';
import 'package:open_vts/features/vehicles/data/local/vehicle_local_source.dart';
import 'package:open_vts/features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'package:open_vts/features/vehicles/data/sources/vehicle_retrofit_service.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:open_vts/features/vehicles/domain/use_cases/get_vehicles_use_case.dart';

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  return VehicleApiService(ref.watch(dioProvider));
});


final vehicleCacheScopeResolverProvider = Provider<CacheScopeResolver>((ref) {
  return CacheScopeResolver(
    secureStorage: ref.watch(secureStorageProvider),
    dio: ref.watch(dioProvider),
  );
});

final vehicleLocalSourceProvider = Provider<VehicleLocalSource?>((ref) {
  if (kIsWeb) return null;
  return VehicleLocalSource(
    database: ref.watch(appDatabaseProvider),
    scopeResolver: ref.watch(vehicleCacheScopeResolverProvider),
  );
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(
    api: ref.watch(vehicleApiServiceProvider),
    localSource: ref.watch(vehicleLocalSourceProvider),
    listEndpoint: VehicleRoleConfig.admin.listEndpoint,
  );
});

final vehicleRepositoryForConfigProvider =
    Provider.family<VehicleRepository, VehicleRoleConfig>((ref, config) {
  return VehicleRepositoryImpl(
    api: ref.watch(vehicleApiServiceProvider),
    localSource: ref.watch(vehicleLocalSourceProvider),
    listEndpoint: config.listEndpoint,
  );
});

final getVehiclesUseCaseProvider = Provider<GetVehiclesUseCase>((ref) {
  return GetVehiclesUseCase(ref.watch(vehicleRepositoryProvider));
});

final getVehiclesUseCaseForConfigProvider =
    Provider.family<GetVehiclesUseCase, VehicleRoleConfig>((ref, config) {
  return GetVehiclesUseCase(ref.watch(vehicleRepositoryForConfigProvider(config)));
});
