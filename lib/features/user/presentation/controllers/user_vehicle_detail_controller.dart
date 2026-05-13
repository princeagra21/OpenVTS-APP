import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_vehicle_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';

class UserVehicleDetailState {
  const UserVehicleDetailState({this.detail, this.isLoading = false, this.errorMessage});
  final UserVehicleDetails? detail;
  final bool isLoading;
  final String? errorMessage;
  UserVehicleDetailState copyWith({UserVehicleDetails? detail, bool? isLoading, Object? errorMessage = _unchanged}) => UserVehicleDetailState(detail: detail ?? this.detail, isLoading: isLoading ?? this.isLoading, errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?);
}
const Object _unchanged = Object();
final userVehicleDetailControllerProvider = StateNotifierProvider.autoDispose<UserVehicleDetailController, UserVehicleDetailState>((ref) => UserVehicleDetailController(ref));
class UserVehicleDetailController extends StateNotifier<UserVehicleDetailState> {
  UserVehicleDetailController(this._ref) : super(const UserVehicleDetailState());
  final Ref _ref;
  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserVehicleDetailUseCaseProvider)(id);
    if (!mounted) return;
    result.when(success: (detail) => state = state.copyWith(detail: detail, isLoading: false), failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, "Couldn't load vehicle.")));
  }
  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
