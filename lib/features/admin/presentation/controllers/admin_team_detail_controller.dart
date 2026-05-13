import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_team_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';

class AdminTeamDetailState {
  const AdminTeamDetailState({
    this.detail,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final AdminTeamListItem? detail;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  AdminTeamDetailState copyWith({
    AdminTeamListItem? detail,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _unchanged,
  }) => AdminTeamDetailState(
        detail: detail ?? this.detail,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      );
}

const Object _unchanged = Object();

final adminTeamDetailControllerProvider = StateNotifierProvider.autoDispose.family<AdminTeamDetailController, AdminTeamDetailState, String>((ref, teamId) {
  final controller = AdminTeamDetailController(ref, teamId);
  controller.load();
  return controller;
});

class AdminTeamDetailController extends StateNotifier<AdminTeamDetailState> {
  AdminTeamDetailController(this._ref, this._teamId) : super(const AdminTeamDetailState());
  final Ref _ref;
  final String _teamId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getAdminTeamDetailUseCaseProvider)(_teamId);
    if (!mounted) return;
    result.when(
      success: (detail) => state = state.copyWith(detail: detail, isLoading: false),
      failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load team.")),
    );
  }

  Future<bool> updateStatus(bool isActive) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _ref.read(updateAdminTeamUseCaseProvider).updateStatus(_teamId, isActive);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSaving: false); load(); return true; }, failure: (error) { state = state.copyWith(isSaving: false, errorMessage: _message(error, fallback: "Couldn't update team status.")); return false; });
  }

  Future<bool> updatePassword(String password) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _ref.read(updateAdminTeamUseCaseProvider).updatePassword(_teamId, password);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSaving: false); return true; }, failure: (error) { state = state.copyWith(isSaving: false, errorMessage: _message(error, fallback: "Couldn't update password.")); return false; });
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
