import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_device_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

class AdminDeviceFormEffect {
  const AdminDeviceFormEffect.success(this.message) : isError = false;
  const AdminDeviceFormEffect.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

class AdminDeviceFormState {
  const AdminDeviceFormState({
    this.deviceTypes = const <DeviceTypeOption>[],
    this.sims = const <SimOption>[],
    this.providers = const <SimProviderOption>[],
    this.isLoadingRefs = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.effect,
  });

  final List<DeviceTypeOption> deviceTypes;
  final List<SimOption> sims;
  final List<SimProviderOption> providers;
  final bool isLoadingRefs;
  final bool isSubmitting;
  final String? errorMessage;
  final AdminDeviceFormEffect? effect;

  AdminDeviceFormState copyWith({
    List<DeviceTypeOption>? deviceTypes,
    List<SimOption>? sims,
    List<SimProviderOption>? providers,
    bool? isLoadingRefs,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) => AdminDeviceFormState(
        deviceTypes: deviceTypes ?? this.deviceTypes,
        sims: sims ?? this.sims,
        providers: providers ?? this.providers,
        isLoadingRefs: isLoadingRefs ?? this.isLoadingRefs,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
        effect: identical(effect, _unchanged) ? this.effect : effect as AdminDeviceFormEffect?,
      );
}

const Object _unchanged = Object();

final adminDeviceFormControllerProvider = StateNotifierProvider.autoDispose<AdminDeviceFormController, AdminDeviceFormState>((ref) {
  return AdminDeviceFormController(ref);
});

class AdminDeviceFormController extends StateNotifier<AdminDeviceFormState> {
  AdminDeviceFormController(this._ref) : super(const AdminDeviceFormState());
  final Ref _ref;

  Future<void> loadReferences({bool quickSims = false}) async {
    state = state.copyWith(isLoadingRefs: true, errorMessage: null, effect: null);
    final result = await _ref.read(loadAdminDeviceReferencesUseCaseProvider)(quickSims: quickSims);
    if (!mounted) return;
    result.when(
      success: (refs) => state = state.copyWith(
        deviceTypes: refs.deviceTypes,
        sims: refs.sims,
        providers: refs.providers,
        isLoadingRefs: false,
      ),
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load device references.");
        state = state.copyWith(isLoadingRefs: false, errorMessage: message, effect: AdminDeviceFormEffect.error(message));
      },
    );
  }

  Future<bool> createSimCard(CreateAdminSimCardMutationInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final result = await _ref.read(createAdminSimCardUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false, effect: const AdminDeviceFormEffect.success('SIM card created.')); return true; }, failure: (error) { final message = _message(error, fallback: "Couldn't create SIM card."); state = state.copyWith(isSubmitting: false, errorMessage: message, effect: AdminDeviceFormEffect.error(message)); return false; });
  }

  Future<bool> createDevice(CreateAdminDeviceMutationInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final result = await _ref.read(createAdminDeviceUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false, effect: const AdminDeviceFormEffect.success('Device added.')); return true; }, failure: (error) { final message = _message(error, fallback: "Couldn't add device."); state = state.copyWith(isSubmitting: false, errorMessage: message, effect: AdminDeviceFormEffect.error(message)); return false; });
  }

  Future<bool> createDeviceAndSim(CreateAdminDeviceAndSimMutationInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final result = await _ref.read(createAdminDeviceAndSimUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false, effect: const AdminDeviceFormEffect.success('Device and SIM added.')); return true; }, failure: (error) { final message = _message(error, fallback: "Couldn't add device and SIM."); state = state.copyWith(isSubmitting: false, errorMessage: message, effect: AdminDeviceFormEffect.error(message)); return false; });
  }

  Future<bool> updateDevice(String deviceId, UpdateAdminDeviceMutationInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateAdminDeviceUseCaseProvider)(deviceId, input);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false, effect: const AdminDeviceFormEffect.success('Device updated.')); return true; }, failure: (error) { final message = _message(error, fallback: "Couldn't update device."); state = state.copyWith(isSubmitting: false, errorMessage: message, effect: AdminDeviceFormEffect.error(message)); return false; });
  }

  void clearEffect() {
    if (state.effect == null) return;
    state = state.copyWith(effect: null);
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
