import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_sub_user_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';

class UserSubUserListState {
  const UserSubUserListState({this.items = const [], this.isLoading = false, this.errorMessage});
  final List<UserSubUserItem> items;
  final bool isLoading;
  final String? errorMessage;
  UserSubUserListState copyWith({List<UserSubUserItem>? items, bool? isLoading, Object? errorMessage = _unchanged}) => UserSubUserListState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
  );
}
const Object _unchanged = Object();

final userSubUserListControllerProvider = StateNotifierProvider.autoDispose<UserSubUserListController, UserSubUserListState>((ref) => UserSubUserListController(ref));

class UserSubUserListController extends StateNotifier<UserSubUserListState> {
  UserSubUserListController(this._ref) : super(const UserSubUserListState());
  final Ref _ref;

  Future<void> load({int page = 1, int limit = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserSubUsersUseCaseProvider)(page: page, limit: limit);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false, errorMessage: null),
      failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, "Couldn't load sub-users.")),
    );
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
