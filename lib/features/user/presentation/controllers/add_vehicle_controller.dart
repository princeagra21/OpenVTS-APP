import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/user/di/user_vehicle_form_providers.dart';
import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';

class UserAddVehicleState {
  const UserAddVehicleState({
    this.vehicleTypes = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<ReferenceOption> vehicleTypes;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  UserAddVehicleState copyWith({
    List<ReferenceOption>? vehicleTypes,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) {
    return UserAddVehicleState(
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final userAddVehicleControllerProvider = StateNotifierProvider.autoDispose<UserAddVehicleController, UserAddVehicleState>((ref) {
  final controller = UserAddVehicleController(ref);
  controller.loadVehicleTypes();
  return controller;
});

class UserAddVehicleController extends StateNotifier<UserAddVehicleState> {
  UserAddVehicleController(this._ref) : super(const UserAddVehicleState());

  final Ref _ref;

  Future<void> loadVehicleTypes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserVehicleTypesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(vehicleTypes: items, isLoading: false),
      failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error)),
    );
  }

  Future<bool> submit(CreateUserVehicleInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createUserVehicleUseCaseProvider)(input);
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
