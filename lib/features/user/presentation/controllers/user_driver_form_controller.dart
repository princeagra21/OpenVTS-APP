import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_driver_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';

class UserDriverFormState {
  const UserDriverFormState({this.detail, this.isLoading = false, this.isSubmitting = false, this.errorMessage});
  final UserDriverDetails? detail;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  UserDriverFormState copyWith({UserDriverDetails? detail, bool? isLoading, bool? isSubmitting, Object? errorMessage = _unchanged}) => UserDriverFormState(detail: detail ?? this.detail, isLoading: isLoading ?? this.isLoading, isSubmitting: isSubmitting ?? this.isSubmitting, errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?);
}
const Object _unchanged = Object();
final userDriverFormControllerProvider = StateNotifierProvider.autoDispose<UserDriverFormController, UserDriverFormState>((ref) => UserDriverFormController(ref));
class UserDriverFormController extends StateNotifier<UserDriverFormState> {
  UserDriverFormController(this._ref) : super(const UserDriverFormState());
  final Ref _ref;
  Future<void> loadDetail(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserDriverDetailUseCaseProvider)(id);
    if (!mounted) return;
    result.when(success: (detail) => state = state.copyWith(detail: detail, isLoading: false), failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, "Couldn't load driver.")));
  }
  Future<bool> create(Map<String, Object?> payload) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createUserDriverUseCaseProvider)(payload);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't save driver.")); return false; });
  }
  Future<bool> update(String id, Map<String, Object?> payload) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(updateUserDriverUseCaseProvider)(id, payload);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't save driver.")); return false; });
  }
  Future<bool> delete(String id) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(deleteUserDriverUseCaseProvider)(id);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't delete driver.")); return false; });
  }
  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
