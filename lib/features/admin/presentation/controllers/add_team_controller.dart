import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_workflow_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

class AddTeamFormState {
  const AddTeamFormState({
    this.prefixes = const [],
    this.isLoadingPrefixes = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<MobilePrefixOption> prefixes;
  final bool isLoadingPrefixes;
  final bool isSubmitting;
  final String? errorMessage;

  AddTeamFormState copyWith({
    List<MobilePrefixOption>? prefixes,
    bool? isLoadingPrefixes,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) {
    return AddTeamFormState(
      prefixes: prefixes ?? this.prefixes,
      isLoadingPrefixes: isLoadingPrefixes ?? this.isLoadingPrefixes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final addTeamControllerProvider = StateNotifierProvider.autoDispose<AddTeamController, AddTeamFormState>((ref) {
  final controller = AddTeamController(ref);
  controller.loadPrefixes();
  return controller;
});

class AddTeamController extends StateNotifier<AddTeamFormState> {
  AddTeamController(this._ref) : super(const AddTeamFormState());

  final Ref _ref;

  Future<void> loadPrefixes() async {
    state = state.copyWith(isLoadingPrefixes: true, errorMessage: null);
    final result = await _ref.read(getMobilePrefixesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) {
        state = state.copyWith(
          prefixes: items,
          isLoadingPrefixes: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingPrefixes: false,
          errorMessage: _message(error),
        );
      },
    );
  }

  Future<bool> submit({
    required String name,
    required String email,
    required String mobilePrefix,
    required String mobileNumber,
    required String username,
    required String password,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createAdminTeamUseCaseProvider)(
          CreateAdminTeamInput(
            name: name,
            email: email,
            mobilePrefix: mobilePrefix,
            mobileNumber: mobileNumber,
            username: username,
            password: password,
          ),
        );
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, errorMessage: _message(error));
        return false;
      },
    );
  }

  String _message(Object error) {
    if (error is AppError) return error.message;
    final value = error.toString();
    return value.isEmpty ? 'Something went wrong.' : value;
  }
}
