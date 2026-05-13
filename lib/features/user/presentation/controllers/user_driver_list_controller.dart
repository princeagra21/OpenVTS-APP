import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/di/user_driver_providers.dart';

class UserDriverListState {
  const UserDriverListState({this.items = const [], this.isLoading = false, this.errorMessage});
  final List<AdminDriverListItem> items;
  final bool isLoading;
  final String? errorMessage;
  UserDriverListState copyWith({List<AdminDriverListItem>? items, bool? isLoading, Object? errorMessage = _unchanged}) => UserDriverListState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading, errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?);
}
const Object _unchanged = Object();
final userDriverListControllerProvider = StateNotifierProvider.autoDispose<UserDriverListController, UserDriverListState>((ref) => UserDriverListController(ref));
class UserDriverListController extends StateNotifier<UserDriverListState> {
  UserDriverListController(this._ref) : super(const UserDriverListState());
  final Ref _ref;
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserDriversUseCaseProvider)();
    if (!mounted) return;
    result.when(success: (items) => state = state.copyWith(items: items, isLoading: false), failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, "Couldn't load drivers.")));
  }
  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
