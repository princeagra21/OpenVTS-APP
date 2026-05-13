import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';

class AdminDriverListState {
  const AdminDriverListState({
    this.items = const <AdminDriverListItem>[],
    this.isLoading = false,
    this.errorMessage,
    this.updatingIds = const <String>{},
  });

  final List<AdminDriverListItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> updatingIds;

  AdminDriverListState copyWith({
    List<AdminDriverListItem>? items,
    bool? isLoading,
    Object? errorMessage = _unchanged,
    Set<String>? updatingIds,
  }) {
    return AdminDriverListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      updatingIds: updatingIds ?? this.updatingIds,
    );
  }
}

const Object _unchanged = Object();

final adminDriverListControllerProvider = StateNotifierProvider.autoDispose<AdminDriverListController, AdminDriverListState>((ref) {
  return AdminDriverListController(ref);
});

class AdminDriverListController extends StateNotifier<AdminDriverListState> {
  AdminDriverListController(this._ref) : super(const AdminDriverListState());
  final Ref _ref;

  Future<void> loadDrivers({String? search, String? status, int page = 1, int limit = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getAdminDriversUseCaseProvider)(search: search, status: status, page: page, limit: limit);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false, errorMessage: null),
      failure: (error) => state = state.copyWith(items: const <AdminDriverListItem>[], isLoading: false, errorMessage: _message(error, fallback: "Couldn't load drivers.")),
    );
  }

  Future<bool> updateStatus(AdminDriverListItem item, bool nextValue) async {
    final id = item.id.trim();
    if (id.isEmpty || state.updatingIds.contains(id)) return false;
    final previousItems = state.items;
    final mapper = _ref.read(adminDriverMapperProvider);
    state = state.copyWith(
      items: previousItems.map((driver) => driver.id == id ? mapper.withActive(driver, nextValue) : driver).toList(growable: false),
      updatingIds: <String>{...state.updatingIds, id},
      errorMessage: null,
    );
    final result = await _ref.read(updateAdminDriverUseCaseProvider)(id, nextValue);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id), errorMessage: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          items: previousItems,
          updatingIds: <String>{...state.updatingIds}..remove(id),
          errorMessage: _message(error, fallback: "Couldn't update driver status."),
        );
        return false;
      },
    );
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
