import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_route_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_route_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_route_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/assign_route_driver_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/create_user_route_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_routes_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/delete_user_route_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/update_user_route_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/optimize_user_route_use_case.dart';

final userRouteApiServiceProvider = Provider<UserRouteApiService>((ref) => UserRouteApiService(ref.watch(appDioProvider)));
final userRouteMapperProvider = Provider<UserRouteMapper>((ref) => const UserRouteMapper());
final userRouteRepositoryProvider = Provider<UserRouteRepository>((ref) => UserRouteRepositoryImpl(api: ref.watch(userRouteApiServiceProvider), mapper: ref.watch(userRouteMapperProvider)));
final getUserRoutesUseCaseProvider = Provider<GetUserRoutesUseCase>((ref) => GetUserRoutesUseCase(ref.watch(userRouteRepositoryProvider)));
final createUserRouteUseCaseProvider = Provider<CreateUserRouteUseCase>((ref) => CreateUserRouteUseCase(ref.watch(userRouteRepositoryProvider)));
final updateUserRouteUseCaseProvider = Provider<UpdateUserRouteUseCase>((ref) => UpdateUserRouteUseCase(ref.watch(userRouteRepositoryProvider)));
final deleteUserRouteUseCaseProvider = Provider<DeleteUserRouteUseCase>((ref) => DeleteUserRouteUseCase(ref.watch(userRouteRepositoryProvider)));
final optimizeUserRouteUseCaseProvider = Provider<OptimizeUserRouteUseCase>((ref) => const OptimizeUserRouteUseCase());
final assignRouteDriverUseCaseProvider = Provider<AssignRouteDriverUseCase>((ref) => AssignRouteDriverUseCase(ref.watch(userRouteRepositoryProvider)));

