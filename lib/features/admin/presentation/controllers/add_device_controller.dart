import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_workflow_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';

class AddDeviceFormState {
  const AddDeviceFormState({
    this.deviceTypes = const [],
    this.sims = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<DeviceTypeOption> deviceTypes;
  final List<SimOption> sims;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  AddDeviceFormState copyWith({
    List<DeviceTypeOption>? deviceTypes,
    List<SimOption>? sims,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) {
    return AddDeviceFormState(
      deviceTypes: deviceTypes ?? this.deviceTypes,
      sims: sims ?? this.sims,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final addDeviceControllerProvider = StateNotifierProvider.autoDispose<AddDeviceController, AddDeviceFormState>((ref) {
  final controller = AddDeviceController(ref);
  controller.loadReferenceData();
  return controller;
});

class AddDeviceController extends StateNotifier<AddDeviceFormState> {
  AddDeviceController(this._ref) : super(const AddDeviceFormState());

  final Ref _ref;

  Future<void> loadReferenceData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(loadAdminDeviceFormDataUseCaseProvider)();
    if (!mounted) return;
    state = result.when(
      success: (data) => state.copyWith(
        deviceTypes: data.deviceTypes,
        sims: data.sims,
        isLoading: false,
        errorMessage: null,
      ),
      failure: (error) => state.copyWith(
        isLoading: false,
        errorMessage: _message(error),
      ),
    );
  }

  Future<bool> submit({
    required String imei,
    required String deviceTypeId,
    String? simId,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createAdminDeviceUseCaseProvider)(
          CreateAdminDeviceMutationInput(
            imei: imei,
            deviceTypeId: deviceTypeId,
            simId: simId,
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
