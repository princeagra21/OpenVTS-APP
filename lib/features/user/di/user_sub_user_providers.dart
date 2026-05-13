import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_sub_user_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_sub_user_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_sub_user_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/create_user_sub_user_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_sub_user_detail_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_sub_users_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/update_user_sub_user_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/delete_user_sub_user_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/unassign_user_sub_user_vehicle_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/assign_user_sub_user_vehicle_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_sub_user_vehicles_use_case.dart';

final userSubUserApiServiceProvider = Provider<UserSubUserApiService>((ref) => UserSubUserApiService(ref.watch(appDioProvider)));
final userSubUserMapperProvider = Provider<UserSubUserMapper>((ref) => const UserSubUserMapper());
final userSubUserRepositoryProvider = Provider<UserSubUserRepository>((ref) => UserSubUserRepositoryImpl(api: ref.watch(userSubUserApiServiceProvider), mapper: ref.watch(userSubUserMapperProvider)));
final getUserSubUsersUseCaseProvider = Provider<GetUserSubUsersUseCase>((ref) => GetUserSubUsersUseCase(ref.watch(userSubUserRepositoryProvider)));
final getUserSubUserDetailUseCaseProvider = Provider<GetUserSubUserDetailUseCase>((ref) => GetUserSubUserDetailUseCase(ref.watch(userSubUserRepositoryProvider)));
final createUserSubUserUseCaseProvider = Provider<CreateUserSubUserUseCase>((ref) => CreateUserSubUserUseCase(ref.watch(userSubUserRepositoryProvider)));
final updateUserSubUserUseCaseProvider = Provider<UpdateUserSubUserUseCase>((ref) => UpdateUserSubUserUseCase(ref.watch(userSubUserRepositoryProvider)));

final deleteUserSubUserUseCaseProvider = Provider<DeleteUserSubUserUseCase>((ref) => DeleteUserSubUserUseCase(ref.watch(userSubUserRepositoryProvider)));

final getUserSubUserVehiclesUseCaseProvider = Provider<GetUserSubUserVehiclesUseCase>((ref) => GetUserSubUserVehiclesUseCase(ref.watch(userSubUserRepositoryProvider)));
final assignUserSubUserVehicleUseCaseProvider = Provider<AssignUserSubUserVehicleUseCase>((ref) => AssignUserSubUserVehicleUseCase(ref.watch(userSubUserRepositoryProvider)));
final unassignUserSubUserVehicleUseCaseProvider = Provider<UnassignUserSubUserVehicleUseCase>((ref) => UnassignUserSubUserVehicleUseCase(ref.watch(userSubUserRepositoryProvider)));
