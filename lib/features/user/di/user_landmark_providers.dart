import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_landmark_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_landmark_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_landmark_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/create_user_landmark_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/delete_user_landmark_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_landmarks_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/update_user_landmark_use_case.dart';

final userLandmarkApiServiceProvider = Provider<UserLandmarkApiService>((ref) => UserLandmarkApiService(ref.watch(appDioProvider)));
final userLandmarkMapperProvider = Provider<UserLandmarkMapper>((ref) => const UserLandmarkMapper());
final userLandmarkRepositoryProvider = Provider<UserLandmarkRepository>((ref) => UserLandmarkRepositoryImpl(api: ref.watch(userLandmarkApiServiceProvider), mapper: ref.watch(userLandmarkMapperProvider)));
final getUserLandmarksUseCaseProvider = Provider<GetUserLandmarksUseCase>((ref) => GetUserLandmarksUseCase(ref.watch(userLandmarkRepositoryProvider)));
final createUserLandmarkUseCaseProvider = Provider<CreateUserLandmarkUseCase>((ref) => CreateUserLandmarkUseCase(ref.watch(userLandmarkRepositoryProvider)));
final updateUserLandmarkUseCaseProvider = Provider<UpdateUserLandmarkUseCase>((ref) => UpdateUserLandmarkUseCase(ref.watch(userLandmarkRepositoryProvider)));
final deleteUserLandmarkUseCaseProvider = Provider<DeleteUserLandmarkUseCase>((ref) => DeleteUserLandmarkUseCase(ref.watch(userLandmarkRepositoryProvider)));
