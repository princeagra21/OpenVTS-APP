import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transactions_summary.dart';

class AdminTransactionsState {
  const AdminTransactionsState({this.items = const <AdminTransactionItem>[], this.summary, this.isLoading = false, this.error});
  final List<AdminTransactionItem> items;
  final AdminTransactionsSummary? summary;
  final bool isLoading;
  final AppError? error;

  AdminTransactionsState copyWith({List<AdminTransactionItem>? items, AdminTransactionsSummary? summary, bool clearSummary = false, bool? isLoading, Object? error = _unchanged}) {
    return AdminTransactionsState(
      items: items ?? this.items,
      summary: clearSummary ? null : summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminTransactionsController extends StateNotifier<AdminTransactionsState> {
  AdminTransactionsController(this._ref) : super(const AdminTransactionsState());
  final Ref _ref;

  Future<bool> load({String? search, String? status, int? page, int? limit, String? from, String? to}) async {
    state = state.copyWith(isLoading: true, error: null);
    final listResult = await _ref.read(getAdminTransactionsUseCaseProvider)(search: search, status: status, page: page, limit: limit, from: from, to: to);
    final summaryResult = await _ref.read(getAdminTransactionsUseCaseProvider).summary();
    if (!mounted) return false;

    var items = const <AdminTransactionItem>[];
    AdminTransactionsSummary? summary;
    AppError? firstError;

    listResult.when(success: (value) => items = value, failure: (error) => firstError ??= error);
    summaryResult.when(success: (value) => summary = value, failure: (error) => firstError ??= error);

    state = state.copyWith(items: items, summary: summary, clearSummary: summary == null, isLoading: false, error: firstError);
    return firstError == null;
  }
}
