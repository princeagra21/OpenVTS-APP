import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

class AdminUserListState {
  const AdminUserListState({
    this.items = const <AdminUserListItem>[],
    this.isLoading = false,
    this.updatingIds = const <String>{},
    this.loggingInIds = const <String>{},
    this.error,
  });

  final List<AdminUserListItem> items;
  final bool isLoading;
  final Set<String> updatingIds;
  final Set<String> loggingInIds;
  final AppError? error;

  bool get isEmpty => !isLoading && items.isEmpty && error == null;

  AdminUserListState copyWith({
    List<AdminUserListItem>? items,
    bool? isLoading,
    Set<String>? updatingIds,
    Set<String>? loggingInIds,
    Object? error = _unchanged,
  }) {
    return AdminUserListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      updatingIds: updatingIds ?? this.updatingIds,
      loggingInIds: loggingInIds ?? this.loggingInIds,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminUserListController extends StateNotifier<AdminUserListState> {
  AdminUserListController(this._ref) : super(const AdminUserListState());

  final Ref _ref;

  Future<void> load({String? search, String? status, int? page, int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminUsersUseCaseProvider)(
          search: search,
          status: status,
          page: page,
          limit: limit,
        );
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false),
      failure: (error) => state = state.copyWith(items: const <AdminUserListItem>[], isLoading: false, error: error),
    );
  }

  Future<bool> updateStatus(AdminUserListItem item, bool isActive) async {
    final id = item.id.trim();
    if (id.isEmpty) return false;
    final previousItems = state.items;
    state = state.copyWith(
      items: _replaceUserStatus(previousItems, id, isActive),
      updatingIds: <String>{...state.updatingIds, id},
      error: null,
    );
    final result = await _ref.read(updateAdminUserStatusUseCaseProvider)(id, isActive);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id));
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          items: previousItems,
          updatingIds: <String>{...state.updatingIds}..remove(id),
          error: error,
        );
        return false;
      },
    );
  }

  List<AdminUserListItem> _replaceUserStatus(
    List<AdminUserListItem> items,
    String userId,
    bool isActive,
  ) {
    return items.map((user) {
      if (user.id != userId) return user;
      final raw = Map<String, dynamic>.from(user.raw);
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      if (!isActive) {
        raw['status'] = 'Disabled';
      } else if (user.statusLabel.toLowerCase() == 'disabled') {
        raw['status'] = 'Verified';
      }
      return AdminUserListItem.fromRaw(raw);
    }).toList(growable: false);
  }

  Future<String?> loginAsUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;
    state = state.copyWith(loggingInIds: <String>{...state.loggingInIds, id}, error: null);
    final result = await _ref.read(loginAsAdminUserUseCaseProvider)(id);
    if (!mounted) return null;
    return result.when(
      success: (token) {
        state = state.copyWith(loggingInIds: <String>{...state.loggingInIds}..remove(id));
        return token;
      },
      failure: (error) {
        state = state.copyWith(loggingInIds: <String>{...state.loggingInIds}..remove(id), error: error);
        return null;
      },
    );
  }
}
