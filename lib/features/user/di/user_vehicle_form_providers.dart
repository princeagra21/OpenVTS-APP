import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_form_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicle_form_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_form_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_form_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/create_user_vehicle_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_vehicle_types_use_case.dart';

final userVehicleFormApiServiceProvider = Provider<UserVehicleFormApiService>((ref) {
  return UserVehicleFormApiService(ref.watch(appDioProvider));
});

final userVehicleFormMapperProvider = Provider<UserVehicleFormMapper>((ref) {
  return const UserVehicleFormMapper();
});

final userVehicleFormRepositoryProvider = Provider<UserVehicleFormRepository>((ref) {
  return UserVehicleFormRepositoryImpl(
    api: ref.watch(userVehicleFormApiServiceProvider),
    mapper: ref.watch(userVehicleFormMapperProvider),
  );
});

final getUserVehicleTypesUseCaseProvider = Provider<GetUserVehicleTypesUseCase>((ref) {
  return GetUserVehicleTypesUseCase(ref.watch(userVehicleFormRepositoryProvider));
});

final createUserVehicleUseCaseProvider = Provider<CreateUserVehicleUseCase>((ref) {
  return CreateUserVehicleUseCase(ref.watch(userVehicleFormRepositoryProvider));
});
