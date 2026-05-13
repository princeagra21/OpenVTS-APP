import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_operations_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_operations_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_operations_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_payment_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_pricing_plan_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_calendar_events_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_logs_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_notifications_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_payments_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_payment_linked_vehicles_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_pricing_plans_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_transactions_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/send_admin_notification_use_case.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_calendar_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_logs_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_notifications_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_payments_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_pricing_plans_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_transactions_controller.dart';

final adminOperationsApiServiceProvider = Provider<AdminOperationsApiService>((ref) {
  return AdminOperationsApiService(ref.watch(appDioProvider));
});

final adminOperationsMapperProvider = Provider<AdminOperationsMapper>((ref) {
  return const AdminOperationsMapper();
});

final adminOperationsRepositoryProvider = Provider<AdminOperationsRepository>((ref) {
  return AdminOperationsRepositoryImpl(
    api: ref.watch(adminOperationsApiServiceProvider),
    mapper: ref.watch(adminOperationsMapperProvider),
  );
});

final getAdminCalendarEventsUseCaseProvider = Provider<GetAdminCalendarEventsUseCase>((ref) {
  return GetAdminCalendarEventsUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminLogsUseCaseProvider = Provider<GetAdminLogsUseCase>((ref) {
  return GetAdminLogsUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminNotificationsUseCaseProvider = Provider<GetAdminNotificationsUseCase>((ref) {
  return GetAdminNotificationsUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final sendAdminNotificationUseCaseProvider = Provider<SendAdminNotificationUseCase>((ref) {
  return SendAdminNotificationUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminPaymentsUseCaseProvider = Provider<GetAdminPaymentsUseCase>((ref) {
  return GetAdminPaymentsUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final createAdminPaymentUseCaseProvider = Provider<CreateAdminPaymentUseCase>((ref) {
  return CreateAdminPaymentUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminPaymentLinkedVehiclesUseCaseProvider = Provider<GetAdminPaymentLinkedVehiclesUseCase>((ref) {
  return GetAdminPaymentLinkedVehiclesUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminPricingPlansUseCaseProvider = Provider<GetAdminPricingPlansUseCase>((ref) {
  return GetAdminPricingPlansUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final createAdminPricingPlanUseCaseProvider = Provider<CreateAdminPricingPlanUseCase>((ref) {
  return CreateAdminPricingPlanUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final getAdminTransactionsUseCaseProvider = Provider<GetAdminTransactionsUseCase>((ref) {
  return GetAdminTransactionsUseCase(ref.watch(adminOperationsRepositoryProvider));
});

final adminCalendarControllerProvider = StateNotifierProvider.autoDispose<AdminCalendarController, AdminCalendarState>((ref) {
  return AdminCalendarController(ref);
});

final adminLogsControllerProvider = StateNotifierProvider.autoDispose<AdminLogsController, AdminLogsState>((ref) {
  return AdminLogsController(ref);
});

final adminNotificationsControllerProvider = StateNotifierProvider.autoDispose<AdminNotificationsController, AdminNotificationsState>((ref) {
  return AdminNotificationsController(ref);
});

final adminPaymentsControllerProvider = StateNotifierProvider.autoDispose<AdminPaymentsController, AdminPaymentsState>((ref) {
  return AdminPaymentsController(ref);
});

final adminPricingPlansControllerProvider = StateNotifierProvider.autoDispose<AdminPricingPlansController, AdminPricingPlansState>((ref) {
  return AdminPricingPlansController(ref);
});

final adminTransactionsControllerProvider = StateNotifierProvider.autoDispose<AdminTransactionsController, AdminTransactionsState>((ref) {
  return AdminTransactionsController(ref);
});
