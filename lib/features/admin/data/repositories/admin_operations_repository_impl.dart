import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_operations_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_operations_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_operations_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_calendar_event_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_log_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transactions_summary.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_recipient.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class AdminOperationsRepositoryImpl implements AdminOperationsRepository {
  const AdminOperationsRepositoryImpl({
    required AdminOperationsApiService api,
    required AdminOperationsMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminOperationsApiService _api;
  final AdminOperationsMapper _mapper;

  @override
  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarEvents({required String from, required String to}) {
    return _guard(() async {
      final response = await _api.getCalendarEvents(query: <String, Object?>{'from': from, 'to': to});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.calendarEvents(response));
    });
  }

  @override
  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarDayEvents({required String date}) {
    return _guard(() async {
      final response = await _api.getCalendarDay(query: <String, Object?>{'date': date});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.calendarDayEvents(response, date: date));
    });
  }

  @override
  Future<Result<List<AdminLogItem>, AppError>> getLogs({String? search, String? level, int? page, int? limit, String? from, String? to}) {
    return _guard(() async {
      final requestedLimit = limit ?? 20;
      final activityLimit = _clamp(requestedLimit, min: 5, max: 50);
      final eventsLimit = _clamp(requestedLimit, min: 1, max: 200);
      final activityQuery = <String, Object?>{'limit': activityLimit};
      final q = search?.trim() ?? '';
      if (q.isNotEmpty) activityQuery['q'] = q;
      if (from != null && from.trim().isNotEmpty) activityQuery['from'] = from.trim();
      if (to != null && to.trim().isNotEmpty) activityQuery['to'] = to.trim();
      if (page != null) activityQuery['cursorId'] = page;

      final eventsQuery = <String, Object?>{'limit': eventsLimit};
      final severity = _mapLevelToSeverity(level);
      if (severity != null) eventsQuery['severity'] = severity;

      final responses = await Future.wait([
        _api.getLogOptions(),
        _api.getLogActivity(query: activityQuery),
        _api.getLogEvents(query: eventsQuery),
      ]);
      final failures = responses.map(_failureIfRejected).whereType<AppError>().toList();
      if (failures.length == responses.length) return Result.failure(failures.first);
      return Result.success(_mapper.logsFromResponses(responses.where((r) => _failureIfRejected(r) == null)));
    });
  }

  @override
  Future<Result<List<AdminNotificationItem>, AppError>> getNotifications() {
    return _guard(() async {
      final response = await _api.getNotifications();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.notifications(response));
    });
  }

  @override
  Future<Result<void, AppError>> markNotificationRead(String id) {
    return _guardVoid(() => _api.markNotificationRead(id));
  }

  @override
  Future<Result<void, AppError>> markAllNotificationsRead() {
    return _guardVoid(() => _api.markAllNotificationsRead(const AdminEmptyRequestDto()));
  }

  @override
  Future<Result<List<AdminUserRecipient>, AppError>> searchNotificationRecipients({String query = ''}) {
    return _guard(() async {
      final q = query.trim();
      final response = await _api.searchNotificationRecipients(query: q.isEmpty ? null : <String, Object?>{'search': q});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.recipients(response));
    });
  }

  @override
  Future<Result<void, AppError>> sendNotification({required String channel, required List<String> userIds, String? subject, required String message}) {
    return _guardVoid(() => _api.sendNotification(AdminSendNotificationRequestDto(
          channel: channel,
          userIds: userIds,
          subject: subject,
          message: message,
        )));
  }

  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getPayments({String? search, String? status, int? page, int? limit, String? from, String? to}) {
    return _guard(() async {
      final response = await _api.getPayments(query: _query(search: search, status: status, page: page, limit: limit, from: from, to: to));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.payments(response));
    });
  }

  @override
  Future<Result<void, AppError>> createPayment({required String userId, required List<String> vehicleIds, required String amount, required String paymentMode}) {
    return _guardVoid(() => _api.createPayment(AdminCreatePaymentRequestDto(
          userId: _toNumOrString(userId.trim()),
          vehicleIds: vehicleIds.map((id) => _toNumOrString(id.trim())).toList(),
          amount: amount.trim(),
          paymentMode: paymentMode.trim(),
        )));
  }

  @override
  Future<Result<List<PricingPlan>, AppError>> getPricingPlans() {
    return _guard(() async {
      final response = await _api.getPricingPlans();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.pricingPlans(response));
    });
  }

  @override
  Future<Result<Map<String, Object?>, AppError>> createPricingPlan({required String name, required int durationDays, required num price, required String currency}) {
    return _guard(() async {
      final response = await _api.createPricingPlan(AdminCreatePricingPlanRequestDto(name: name, durationDays: durationDays, price: price, currency: currency));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(response.payload ?? const <String, Object?>{});
    });
  }

  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getTransactions({String? search, String? status, int? page, int? limit, String? from, String? to}) {
    return _guard(() async {
      final response = await _api.getTransactions(query: _query(search: search, status: status, page: page, limit: limit, from: from, to: to));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.transactions(response));
    });
  }

  @override
  Future<Result<AdminTransactionsSummary, AppError>> getTransactionsSummary() {
    return _guard(() async {
      final response = await _api.getTransactionsSummary();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.transactionsSummary(response));
    });
  }

  @override
  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({required String userId}) {
    return _guard(() async {
      final response = await _api.getUserLinkedVehicles(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.linkedVehicles(response));
    });
  }

  Future<Result<T, AppError>> _guard<T>(Future<Result<T, AppError>> Function() body) async {
    try {
      return await body();
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  Future<Result<void, AppError>> _guardVoid(Future<ApiResponse<void>> Function() request) {
    return _guard(() async {
      final response = await request();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    });
  }

  AppError? _failureIfRejected<T>(ApiResponse<T> response) {
    if (response.action) return null;
    final message = response.message.trim().isEmpty ? 'Request failed' : response.message.trim();
    return ServerError(message);
  }

  Map<String, Object?>? _query({String? search, String? status, int? page, int? limit, String? from, String? to}) {
    final query = <String, Object?>{};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (status != null && status.trim().isNotEmpty) query['status'] = status.trim();
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    if (from != null && from.trim().isNotEmpty) query['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) query['to'] = to.trim();
    return query.isEmpty ? null : query;
  }

  int _clamp(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String? _mapLevelToSeverity(String? level) {
    final normalized = (level ?? '').trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') return null;
    if (normalized == 'info') return 'INFO';
    if (normalized == 'warning' || normalized == 'warn') return 'WARNING';
    if (normalized == 'error' || normalized == 'critical') return 'CRITICAL';
    return null;
  }

  Object _toNumOrString(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    return value;
  }
}
