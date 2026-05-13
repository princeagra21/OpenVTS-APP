import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_log_item.dart';

class AdminLogsState {
  const AdminLogsState({this.items = const <AdminLogItem>[], this.isLoading = false, this.error});
  final List<AdminLogItem> items;
  final bool isLoading;
  final AppError? error;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;
  AdminLogsState copyWith({List<AdminLogItem>? items, bool? isLoading, Object? error = _unchanged}) {
    return AdminLogsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminLogsController extends StateNotifier<AdminLogsState> {
  AdminLogsController(this._ref) : super(const AdminLogsState());
  final Ref _ref;

  Future<bool> load({String? search, String? level, int? page, int? limit, String? from, String? to}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminLogsUseCaseProvider)(
          search: search,
          level: level,
          page: page,
          limit: limit,
          from: from,
          to: to,
        );
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(items: items, isLoading: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: const <AdminLogItem>[], isLoading: false, error: error);
        return false;
      },
    );
  }
}
