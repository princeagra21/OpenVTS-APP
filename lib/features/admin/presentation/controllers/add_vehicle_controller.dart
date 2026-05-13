import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/di/admin_form_providers.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';

class AddVehicleFormState {
  const AddVehicleFormState({
    this.users = const [],
    this.quickDevices = const [],
    this.vehicleTypes = const [],
    this.plans = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<AdminFormUserOption> users;
  final List<AdminFormQuickDeviceOption> quickDevices;
  final List<AdminFormVehicleTypeOption> vehicleTypes;
  final List<AdminFormPlanOption> plans;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  AddVehicleFormState copyWith({
    List<AdminFormUserOption>? users,
    List<AdminFormQuickDeviceOption>? quickDevices,
    List<AdminFormVehicleTypeOption>? vehicleTypes,
    List<AdminFormPlanOption>? plans,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) {
    return AddVehicleFormState(
      users: users ?? this.users,
      quickDevices: quickDevices ?? this.quickDevices,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final addVehicleControllerProvider = StateNotifierProvider.autoDispose<
    AddVehicleController, AddVehicleFormState>((ref) {
  final controller = AddVehicleController(ref);
  controller.loadInitialData();
  return controller;
});

class AddVehicleController extends StateNotifier<AddVehicleFormState> {
  AddVehicleController(this._ref) : super(const AddVehicleFormState());

  final Ref _ref;

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _ref.read(loadAddVehicleFormDataUseCaseProvider)();

    if (!mounted) return;

    state = result.when(
      success: (data) => state.copyWith(
        users: data.users,
        quickDevices: data.quickDevices,
        vehicleTypes: data.vehicleTypes,
        plans: data.plans,
        isLoading: false,
        errorMessage: null,
      ),
      failure: (error) => state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage(error),
      ),
    );
  }

  Future<bool> submit({
    required String name,
    required String vin,
    required String plateNumber,
    required String deviceId,
    required String vehicleTypeId,
    required String primaryUserId,
    required String planId,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await _ref.read(createAdminVehicleUseCaseProvider)(
          CreateAdminVehicleInput(
            name: name,
            vin: vin,
            plateNumber: plateNumber,
            deviceId: deviceId,
            vehicleTypeId: vehicleTypeId,
            primaryUserId: primaryUserId,
            planId: planId,
          ),
        );

    if (!mounted) return false;

    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: _errorMessage(error),
        );
        return false;
      },
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  String _errorMessage(Object error) {
    if (error is AppError) return error.message;
    final text = error.toString();
    return text.isEmpty ? 'Something went wrong. Please try again.' : text;
  }
}
