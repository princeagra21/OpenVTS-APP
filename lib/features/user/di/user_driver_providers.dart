import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_driver_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_driver_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_driver_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/create_user_driver_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_driver_detail_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_drivers_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/update_user_driver_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/delete_user_driver_use_case.dart';

final userDriverApiServiceProvider = Provider<UserDriverApiService>((ref) => UserDriverApiService(ref.watch(appDioProvider)));
final userDriverMapperProvider = Provider<UserDriverMapper>((ref) => const UserDriverMapper());
final userDriverRepositoryProvider = Provider<UserDriverRepository>((ref) => UserDriverRepositoryImpl(api: ref.watch(userDriverApiServiceProvider), mapper: ref.watch(userDriverMapperProvider)));
final getUserDriversUseCaseProvider = Provider<GetUserDriversUseCase>((ref) => GetUserDriversUseCase(ref.watch(userDriverRepositoryProvider)));
final getUserDriverDetailUseCaseProvider = Provider<GetUserDriverDetailUseCase>((ref) => GetUserDriverDetailUseCase(ref.watch(userDriverRepositoryProvider)));
final createUserDriverUseCaseProvider = Provider<CreateUserDriverUseCase>((ref) => CreateUserDriverUseCase(ref.watch(userDriverRepositoryProvider)));
final updateUserDriverUseCaseProvider = Provider<UpdateUserDriverUseCase>((ref) => UpdateUserDriverUseCase(ref.watch(userDriverRepositoryProvider)));

final deleteUserDriverUseCaseProvider = Provider<DeleteUserDriverUseCase>((ref) => DeleteUserDriverUseCase(ref.watch(userDriverRepositoryProvider)));
