import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicle_repository_impl.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_vehicle_detail_use_case.dart';

final userVehicleApiServiceProvider = Provider<UserVehicleApiService>((ref) => UserVehicleApiService(ref.watch(appDioProvider)));
final userVehicleMapperProvider = Provider<UserVehicleMapper>((ref) => const UserVehicleMapper());
final userVehicleRepositoryProvider = Provider<UserVehicleRepository>((ref) => UserVehicleRepositoryImpl(api: ref.watch(userVehicleApiServiceProvider), mapper: ref.watch(userVehicleMapperProvider)));
final getUserVehicleDetailUseCaseProvider = Provider<GetUserVehicleDetailUseCase>((ref) => GetUserVehicleDetailUseCase(ref.watch(userVehicleRepositoryProvider)));

// Temporary compatibility provider for the existing document/config tabs.
// The route no longer imports shared bridge providers; document upload/config
// endpoints stay on the legacy delegate until that vertical slice is migrated.
final userVehicleDetailsLegacyDelegateProvider = Provider<UserVehiclesRepository>((ref) => AppContainer.instance.userVehiclesRepository);
