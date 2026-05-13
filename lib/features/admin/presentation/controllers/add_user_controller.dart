import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/admin/di/admin_form_providers.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';

class AddUserSubmitState {
  const AddUserSubmitState({
    this.isSubmitting = false,
    this.isLoadingCountries = false,
    this.isLoadingStates = false,
    this.isLoadingCities = false,
    this.isLoadingPrefixes = false,
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.prefixes = const [],
    this.errorMessage,
  });

  final bool isSubmitting;
  final bool isLoadingCountries;
  final bool isLoadingStates;
  final bool isLoadingCities;
  final bool isLoadingPrefixes;
  final List<CountryOption> countries;
  final List<ReferenceOption> states;
  final List<ReferenceOption> cities;
  final List<MobilePrefixOption> prefixes;
  final String? errorMessage;

  AddUserSubmitState copyWith({
    bool? isSubmitting,
    bool? isLoadingCountries,
    bool? isLoadingStates,
    bool? isLoadingCities,
    bool? isLoadingPrefixes,
    List<CountryOption>? countries,
    List<ReferenceOption>? states,
    List<ReferenceOption>? cities,
    List<MobilePrefixOption>? prefixes,
    Object? errorMessage = _unchanged,
  }) {
    return AddUserSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingStates: isLoadingStates ?? this.isLoadingStates,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingPrefixes: isLoadingPrefixes ?? this.isLoadingPrefixes,
      countries: countries ?? this.countries,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      prefixes: prefixes ?? this.prefixes,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final addUserControllerProvider = StateNotifierProvider.autoDispose<
    AddUserController, AddUserSubmitState>((ref) {
  return AddUserController(ref);
});

class AddUserController extends StateNotifier<AddUserSubmitState> {
  AddUserController(this._ref) : super(const AddUserSubmitState());

  final Ref _ref;
  Future<void> loadReferenceData() async {
    await Future.wait([loadCountries(), loadPrefixes()]);
  }

  Future<void> loadCountries() async {
    state = state.copyWith(isLoadingCountries: true, errorMessage: null);

    final result = await _ref.read(getCountriesUseCaseProvider)();
    if (!mounted) return;

    result.when(
      success: (items) {
        state = state.copyWith(
          countries: items,
          isLoadingCountries: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingCountries: false,
          errorMessage: _errorMessage(error),
        );
      },
    );
  }

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
          errorMessage: _errorMessage(error),
        );
      },
    );
  }

  Future<void> loadStates(String countryCode) async {
    state = state.copyWith(
      isLoadingStates: true,
      states: const [],
      cities: const [],
      errorMessage: null,
    );

    final result = await _ref.read(getStatesUseCaseProvider)(countryCode);
    if (!mounted) return;

    result.when(
      success: (items) {
        state = state.copyWith(
          states: items,
          isLoadingStates: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingStates: false,
          errorMessage: _errorMessage(error),
        );
      },
    );
  }

  Future<void> loadCities(String countryCode, String stateCode) async {
    state = state.copyWith(
      isLoadingCities: true,
      cities: const [],
      errorMessage: null,
    );

    final result = await _ref.read(getCitiesUseCaseProvider)(countryCode, stateCode);
    if (!mounted) return;

    result.when(
      success: (items) {
        state = state.copyWith(
          cities: items,
          isLoadingCities: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingCities: false,
          errorMessage: _errorMessage(error),
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
    required String companyName,
    required String address,
    required String countryCode,
    required String stateCode,
    required String city,
    required String pincode,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await _ref.read(createAdminUserUseCaseProvider)(
          CreateAdminUserInput(
            name: name,
            email: email,
            mobilePrefix: mobilePrefix,
            mobileNumber: mobileNumber,
            username: username,
            password: password,
            companyName: companyName,
            address: address,
            countryCode: countryCode,
            stateCode: stateCode,
            city: city,
            pincode: pincode,
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
