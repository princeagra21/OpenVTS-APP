import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_vehicle_mapper.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_vehicle_repository_impl.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_vehicle_api_service.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_vehicle_detail_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_vehicles_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/send_superadmin_vehicle_command_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_command_options_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_recent_commands_use_case.dart';

final superadminVehicleApiServiceProvider = Provider<SuperadminVehicleApiService>((ref) {
  return SuperadminVehicleApiService(ref.watch(appDioProvider));
});

final superadminVehicleMapperProvider = Provider<SuperadminVehicleMapper>((ref) => const SuperadminVehicleMapper());

final superadminVehicleRepositoryProvider = Provider<SuperadminVehicleRepository>((ref) {
  return SuperadminVehicleRepositoryImpl(
    api: ref.watch(superadminVehicleApiServiceProvider),
    mapper: ref.watch(superadminVehicleMapperProvider),
  );
});

final getSuperadminVehiclesUseCaseProvider = Provider<GetSuperadminVehiclesUseCase>((ref) {
  return GetSuperadminVehiclesUseCase(ref.watch(superadminVehicleRepositoryProvider));
});

final getSuperadminVehicleDetailUseCaseProvider = Provider<GetSuperadminVehicleDetailUseCase>((ref) {
  return GetSuperadminVehicleDetailUseCase(ref.watch(superadminVehicleRepositoryProvider));
});

final sendSuperadminVehicleCommandUseCaseProvider = Provider<SendSuperadminVehicleCommandUseCase>((ref) {
  return SendSuperadminVehicleCommandUseCase(ref.watch(superadminVehicleRepositoryProvider));
});


final getSuperadminCommandOptionsUseCaseProvider = Provider<GetSuperadminCommandOptionsUseCase>((ref) {
  return GetSuperadminCommandOptionsUseCase(ref.watch(superadminVehicleRepositoryProvider));
});

final getSuperadminRecentCommandsUseCaseProvider = Provider<GetSuperadminRecentCommandsUseCase>((ref) {
  return GetSuperadminRecentCommandsUseCase(ref.watch(superadminVehicleRepositoryProvider));
});
