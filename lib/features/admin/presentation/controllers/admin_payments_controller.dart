import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

class AdminPaymentsState {
  const AdminPaymentsState({
    this.items = const <AdminTransactionItem>[],
    this.users = const <AdminUserListItem>[],
    this.linkedVehicles = const <AdminLinkedVehicle>[],
    this.isLoading = false,
    this.isLoadingRefs = false,
    this.isLoadingVehicles = false,
    this.isSubmitting = false,
    this.error,
    this.actionError,
  });

  final List<AdminTransactionItem> items;
  final List<AdminUserListItem> users;
  final List<AdminLinkedVehicle> linkedVehicles;
  final bool isLoading;
  final bool isLoadingRefs;
  final bool isLoadingVehicles;
  final bool isSubmitting;
  final AppError? error;
  final AppError? actionError;

  AdminPaymentsState copyWith({
    List<AdminTransactionItem>? items,
    List<AdminUserListItem>? users,
    List<AdminLinkedVehicle>? linkedVehicles,
    bool? isLoading,
    bool? isLoadingRefs,
    bool? isLoadingVehicles,
    bool? isSubmitting,
    Object? error = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return AdminPaymentsState(
      items: items ?? this.items,
      users: users ?? this.users,
      linkedVehicles: linkedVehicles ?? this.linkedVehicles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRefs: isLoadingRefs ?? this.isLoadingRefs,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
      actionError: identical(actionError, _unchanged) ? this.actionError : actionError as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminPaymentsController extends StateNotifier<AdminPaymentsState> {
  AdminPaymentsController(this._ref) : super(const AdminPaymentsState());
  final Ref _ref;

  Future<bool> loadPayments({String? search, String? status, int? page, int? limit, String? from, String? to}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminPaymentsUseCaseProvider)(search: search, status: status, page: page, limit: limit, from: from, to: to);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(items: items, isLoading: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: const <AdminTransactionItem>[], isLoading: false, error: error);
        return false;
      },
    );
  }

  Future<bool> loadUsers({String? search}) async {
    state = state.copyWith(isLoadingRefs: true, actionError: null);
    final result = await _ref.read(getAdminUsersUseCaseProvider)(search: search, page: 1, limit: 1000);
    if (!mounted) return false;
    return result.when(
      success: (users) {
        state = state.copyWith(users: users, isLoadingRefs: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(users: const <AdminUserListItem>[], isLoadingRefs: false, actionError: error);
        return false;
      },
    );
  }

  Future<bool> loadLinkedVehicles({required String userId}) async {
    state = state.copyWith(isLoadingVehicles: true, actionError: null);
    final result = await _ref.read(getAdminPaymentLinkedVehiclesUseCaseProvider)(userId: userId);
    if (!mounted) return false;
    return result.when(
      success: (vehicles) {
        state = state.copyWith(linkedVehicles: vehicles, isLoadingVehicles: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(linkedVehicles: const <AdminLinkedVehicle>[], isLoadingVehicles: false, actionError: error);
        return false;
      },
    );
  }

  Future<bool> createPayment({required String userId, required List<String> vehicleIds, required String amount, required String paymentMode}) async {
    state = state.copyWith(isSubmitting: true, actionError: null);
    final result = await _ref.read(createAdminPaymentUseCaseProvider)(userId: userId, vehicleIds: vehicleIds, amount: amount, paymentMode: paymentMode);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, actionError: error);
        return false;
      },
    );
  }
}
