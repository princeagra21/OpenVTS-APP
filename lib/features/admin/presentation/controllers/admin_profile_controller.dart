import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

class AdminProfileState {
  const AdminProfileState({
    this.profile,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final AdminProfile? profile;
  final bool isLoading;
  final bool isSubmitting;
  final AppError? error;

  AdminProfileState copyWith({
    AdminProfile? profile,
    bool? isLoading,
    bool? isSubmitting,
    Object? error = _unchanged,
  }) {
    return AdminProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminProfileController extends StateNotifier<AdminProfileState> {
  AdminProfileController(this._ref) : super(const AdminProfileState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminProfileUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (profile) => state = state.copyWith(profile: profile, isLoading: false),
      failure: (error) => state = state.copyWith(isLoading: false, error: error),
    );
  }

  Future<bool> update(Map<String, Object?> payload) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await _ref.read(updateAdminProfileUseCaseProvider)(payload);
    if (!mounted) return false;
    return result.when(
      success: (profile) {
        state = state.copyWith(profile: profile, isSubmitting: false);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, error: error);
        return false;
      },
    );
  }

  Future<bool> updatePassword({required String currentPassword, required String newPassword}) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await _ref.read(updateAdminPasswordUseCaseProvider)(currentPassword: currentPassword, newPassword: newPassword);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, error: error);
        return false;
      },
    );
  }
}
