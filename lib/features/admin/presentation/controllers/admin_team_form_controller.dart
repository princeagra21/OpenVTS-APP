import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_team_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

class AdminTeamFormState {
  const AdminTeamFormState({
    this.prefixes = const <MobilePrefixOption>[],
    this.isLoadingPrefixes = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<MobilePrefixOption> prefixes;
  final bool isLoadingPrefixes;
  final bool isSubmitting;
  final String? errorMessage;

  AdminTeamFormState copyWith({
    List<MobilePrefixOption>? prefixes,
    bool? isLoadingPrefixes,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) => AdminTeamFormState(
        prefixes: prefixes ?? this.prefixes,
        isLoadingPrefixes: isLoadingPrefixes ?? this.isLoadingPrefixes,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      );
}

const Object _unchanged = Object();

final adminTeamFormControllerProvider = StateNotifierProvider.autoDispose<AdminTeamFormController, AdminTeamFormState>((ref) {
  return AdminTeamFormController(ref);
});

class AdminTeamFormController extends StateNotifier<AdminTeamFormState> {
  AdminTeamFormController(this._ref) : super(const AdminTeamFormState());
  final Ref _ref;

  Future<void> loadPrefixes() async {
    state = state.copyWith(isLoadingPrefixes: true, errorMessage: null);
    final result = await _ref.read(getMobilePrefixesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(prefixes: items, isLoadingPrefixes: false),
      failure: (error) => state = state.copyWith(isLoadingPrefixes: false, errorMessage: _message(error, fallback: "Couldn't load mobile prefixes.")),
    );
  }

  Future<bool> updateTeam({required String teamId, required String name, required String email, required String mobilePrefix, required String mobileNumber, required String username}) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(updateAdminTeamUseCaseProvider).updateTeam(teamId: teamId, name: name, email: email, mobilePrefix: mobilePrefix, mobileNumber: mobileNumber, username: username);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, fallback: "Couldn't update team.")); return false; });
  }

  Future<bool> createTeam(CreateAdminTeamInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(updateAdminTeamUseCaseProvider).create(input);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, fallback: "Couldn't create team.")); return false; });
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
