import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/user/data/mappers/user_notification_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_notification_repository_impl.dart';
import 'package:open_vts/features/user/application/push_notification/push_notification_repository.dart';
import 'package:open_vts/features/user/data/sources/user_notification_api_service.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_notification_preferences_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_notifications_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/mark_all_user_notifications_read_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/mark_user_notification_read_use_case.dart';
import 'package:open_vts/features/user/domain/use_cases/update_user_notification_preferences_use_case.dart';

final userNotificationApiServiceProvider = Provider<UserNotificationApiService>((ref) => UserNotificationApiService(ref.watch(appDioProvider)));
final userNotificationMapperProvider = Provider<UserNotificationMapper>((ref) => const UserNotificationMapper());
final userNotificationRepositoryProvider = Provider<UserNotificationRepository>((ref) => UserNotificationRepositoryImpl(api: ref.watch(userNotificationApiServiceProvider), mapper: ref.watch(userNotificationMapperProvider)));
final getUserNotificationsUseCaseProvider = Provider<GetUserNotificationsUseCase>((ref) => GetUserNotificationsUseCase(ref.watch(userNotificationRepositoryProvider)));
final markUserNotificationReadUseCaseProvider = Provider<MarkUserNotificationReadUseCase>((ref) => MarkUserNotificationReadUseCase(ref.watch(userNotificationRepositoryProvider)));
final markAllUserNotificationsReadUseCaseProvider = Provider<MarkAllUserNotificationsReadUseCase>((ref) => MarkAllUserNotificationsReadUseCase(ref.watch(userNotificationRepositoryProvider)));
final getUserNotificationPreferencesUseCaseProvider = Provider<GetUserNotificationPreferencesUseCase>((ref) => GetUserNotificationPreferencesUseCase(ref.watch(userNotificationRepositoryProvider)));
final updateUserNotificationPreferencesUseCaseProvider = Provider<UpdateUserNotificationPreferencesUseCase>((ref) => UpdateUserNotificationPreferencesUseCase(ref.watch(userNotificationRepositoryProvider)));
final pushNotificationAdapterProvider = Provider<PushNotificationRepository>((ref) => PushNotificationRepository(repository: ref.watch(userNotificationRepositoryProvider)));

