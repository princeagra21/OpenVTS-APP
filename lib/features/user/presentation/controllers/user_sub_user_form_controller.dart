import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_sub_user_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

class UserSubUserFormState {
  const UserSubUserFormState({
    this.detail,
    this.vehicles = const [],
    this.allVehicles = const [],
    this.prefixes = const <MobilePrefixOption>[],
    this.countries = const <CountryOption>[],
    this.states = const <ReferenceOption>[],
    this.cities = const <ReferenceOption>[],
    this.isLoading = false,
    this.isLoadingVehicles = false,
    this.isSubmitting = false,
    this.isAssigning = false,
    this.isLoadingPrefixes = false,
    this.isLoadingCountries = false,
    this.isLoadingStates = false,
    this.isLoadingCities = false,
    this.errorMessage,
    this.effect,
  });

  final UserSubUserItem? detail;
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> allVehicles;
  final List<MobilePrefixOption> prefixes;
  final List<CountryOption> countries;
  final List<ReferenceOption> states;
  final List<ReferenceOption> cities;
  final bool isLoading;
  final bool isLoadingVehicles;
  final bool isSubmitting;
  final bool isAssigning;
  final bool isLoadingPrefixes;
  final bool isLoadingCountries;
  final bool isLoadingStates;
  final bool isLoadingCities;
  final String? errorMessage;
  final String? effect;

  UserSubUserFormState copyWith({
    UserSubUserItem? detail,
    List<Map<String, dynamic>>? vehicles,
    List<Map<String, dynamic>>? allVehicles,
    List<MobilePrefixOption>? prefixes,
    List<CountryOption>? countries,
    List<ReferenceOption>? states,
    List<ReferenceOption>? cities,
    bool? isLoading,
    bool? isLoadingVehicles,
    bool? isSubmitting,
    bool? isAssigning,
    bool? isLoadingPrefixes,
    bool? isLoadingCountries,
    bool? isLoadingStates,
    bool? isLoadingCities,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) => UserSubUserFormState(
    detail: detail ?? this.detail,
    vehicles: vehicles ?? this.vehicles,
    allVehicles: allVehicles ?? this.allVehicles,
    prefixes: prefixes ?? this.prefixes,
    countries: countries ?? this.countries,
    states: states ?? this.states,
    cities: cities ?? this.cities,
    isLoading: isLoading ?? this.isLoading,
    isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isAssigning: isAssigning ?? this.isAssigning,
    isLoadingPrefixes: isLoadingPrefixes ?? this.isLoadingPrefixes,
    isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
    isLoadingStates: isLoadingStates ?? this.isLoadingStates,
    isLoadingCities: isLoadingCities ?? this.isLoadingCities,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
    effect: identical(effect, _unchanged) ? this.effect : effect as String?,
  );
}
const Object _unchanged = Object();
final userSubUserFormControllerProvider = StateNotifierProvider.autoDispose<UserSubUserFormController, UserSubUserFormState>((ref) => UserSubUserFormController(ref));

class UserSubUserFormController extends StateNotifier<UserSubUserFormState> {
  UserSubUserFormController(this._ref) : super(const UserSubUserFormState());
  final Ref _ref;

  Future<void> loadDetail(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getUserSubUserDetailUseCaseProvider)(id);
    if (!mounted) return;
    result.when(
      success: (detail) => state = state.copyWith(detail: detail, isLoading: false, errorMessage: null),
      failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, "Couldn't load sub-user.")),
    );
  }


  Future<void> loadVehicles(String id) async {
    state = state.copyWith(isLoadingVehicles: true, errorMessage: null);
    final result = await _ref.read(getUserSubUserVehiclesUseCaseProvider)(id);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(
        vehicles: items.map((item) => <String, dynamic>{for (final entry in item.entries) entry.key: entry.value}).toList(growable: false),
        isLoadingVehicles: false,
      ),
      failure: (error) => state = state.copyWith(
        isLoadingVehicles: false,
        errorMessage: _message(error, "Couldn't load assigned vehicles."),
      ),
    );
  }

  void copyAssignedVehiclesToPicker() {
    state = state.copyWith(allVehicles: state.vehicles);
  }

  Future<bool> assignVehicles(String subUserId, List<String> vehicleIds) async {
    if (state.isAssigning) return false;
    state = state.copyWith(isAssigning: true, errorMessage: null);
    var ok = true;
    for (final id in vehicleIds) {
      final vehicleId = int.tryParse(id);
      if (vehicleId == null) continue;
      final result = await _ref.read(assignUserSubUserVehicleUseCaseProvider)(subUserId, [vehicleId]);
      if (!mounted) return false;
      result.when(
        success: (_) {},
        failure: (error) {
          ok = false;
          state = state.copyWith(errorMessage: _message(error, 'Failed to assign vehicle.'));
        },
      );
      if (!ok) break;
    }
    await loadVehicles(subUserId);
    if (mounted) state = state.copyWith(isAssigning: false);
    return ok;
  }

  Future<bool> unassignVehicle(String subUserId, String rawVehicleId) async {
    if (state.isAssigning) return false;
    final vehicleId = int.tryParse(rawVehicleId);
    if (vehicleId == null) return false;
    state = state.copyWith(isAssigning: true, errorMessage: null);
    final result = await _ref.read(unassignUserSubUserVehicleUseCaseProvider)(subUserId, [vehicleId]);
    if (!mounted) return false;
    final ok = result.when(
      success: (_) => true,
      failure: (error) {
        state = state.copyWith(errorMessage: _message(error, 'Failed to unassign vehicle.'));
        return false;
      },
    );
    await loadVehicles(subUserId);
    if (mounted) state = state.copyWith(isAssigning: false);
    return ok;
  }


  Future<void> loadPrefixes() async {
    state = state.copyWith(isLoadingPrefixes: true, errorMessage: null, effect: null);
    final result = await _ref.read(getMobilePrefixesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(prefixes: items, isLoadingPrefixes: false),
      failure: (error) {
        final message = _message(error, "Couldn't load mobile prefixes.");
        state = state.copyWith(isLoadingPrefixes: false, errorMessage: message, effect: message);
      },
    );
  }

  Future<void> loadCountries() async {
    state = state.copyWith(isLoadingCountries: true, errorMessage: null, effect: null);
    final result = await _ref.read(getCountriesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(countries: items, isLoadingCountries: false),
      failure: (error) {
        final message = _message(error, "Couldn't load countries.");
        state = state.copyWith(isLoadingCountries: false, errorMessage: message, effect: message);
      },
    );
  }

  Future<void> loadStates(String countryCode) async {
    state = state.copyWith(isLoadingStates: true, errorMessage: null, effect: null);
    final result = await _ref.read(getStatesUseCaseProvider)(countryCode);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(states: items, cities: const <ReferenceOption>[], isLoadingStates: false),
      failure: (error) {
        final message = _message(error, "Couldn't load states.");
        state = state.copyWith(isLoadingStates: false, errorMessage: message, effect: message);
      },
    );
  }

  Future<void> loadCities(String countryCode, String stateCode) async {
    state = state.copyWith(isLoadingCities: true, errorMessage: null, effect: null);
    final result = await _ref.read(getCitiesUseCaseProvider)(countryCode, stateCode);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(cities: items, isLoadingCities: false),
      failure: (error) {
        final message = _message(error, "Couldn't load cities.");
        state = state.copyWith(isLoadingCities: false, errorMessage: message, effect: message);
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  Future<bool> create(Map<String, Object?> payload) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createUserSubUserUseCaseProvider)(payload);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't save sub-user.")); return false; });
  }

  Future<bool> update(String id, Map<String, Object?> payload) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(updateUserSubUserUseCaseProvider)(id, payload);
    if (!mounted) return false;
    return result.when(success: (detail) { state = state.copyWith(detail: detail, isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't save sub-user.")); return false; });
  }

  Future<bool> delete(String id) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(deleteUserSubUserUseCaseProvider)(id);
    if (!mounted) return false;
    return result.when(success: (_) { state = state.copyWith(isSubmitting: false); return true; }, failure: (error) { state = state.copyWith(isSubmitting: false, errorMessage: _message(error, "Couldn't delete sub-user.")); return false; });
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
