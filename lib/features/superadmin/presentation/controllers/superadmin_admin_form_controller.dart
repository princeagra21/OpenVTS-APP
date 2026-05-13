import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/superadmin/di/superadmin_admin_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';

class SuperadminAdminFormEffect {
  const SuperadminAdminFormEffect({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;
}

class SuperadminAdminFormState {
  const SuperadminAdminFormState({
    this.countries = const <CountryOption>[],
    this.states = const <ReferenceOption>[],
    this.cities = const <ReferenceOption>[],
    this.selectedCountry,
    this.selectedState,
    this.selectedCity,
    this.phoneCountryIsoCode = 'IN',
    this.phoneCode = '91',
    this.isLoadingReferenceData = false,
    this.isLoadingStates = false,
    this.isLoadingCities = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.effect,
  });

  final List<CountryOption> countries;
  final List<ReferenceOption> states;
  final List<ReferenceOption> cities;
  final CountryOption? selectedCountry;
  final ReferenceOption? selectedState;
  final ReferenceOption? selectedCity;
  final String phoneCountryIsoCode;
  final String phoneCode;
  final bool isLoadingReferenceData;
  final bool isLoadingStates;
  final bool isLoadingCities;
  final bool isSubmitting;
  final String? errorMessage;
  final SuperadminAdminFormEffect? effect;

  SuperadminAdminFormState copyWith({
    List<CountryOption>? countries,
    List<ReferenceOption>? states,
    List<ReferenceOption>? cities,
    Object? selectedCountry = _unchanged,
    Object? selectedState = _unchanged,
    Object? selectedCity = _unchanged,
    String? phoneCountryIsoCode,
    String? phoneCode,
    bool? isLoadingReferenceData,
    bool? isLoadingStates,
    bool? isLoadingCities,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return SuperadminAdminFormState(
      countries: countries ?? this.countries,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      selectedCountry: identical(selectedCountry, _unchanged) ? this.selectedCountry : selectedCountry as CountryOption?,
      selectedState: identical(selectedState, _unchanged) ? this.selectedState : selectedState as ReferenceOption?,
      selectedCity: identical(selectedCity, _unchanged) ? this.selectedCity : selectedCity as ReferenceOption?,
      phoneCountryIsoCode: phoneCountryIsoCode ?? this.phoneCountryIsoCode,
      phoneCode: phoneCode ?? this.phoneCode,
      isLoadingReferenceData: isLoadingReferenceData ?? this.isLoadingReferenceData,
      isLoadingStates: isLoadingStates ?? this.isLoadingStates,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as SuperadminAdminFormEffect?,
    );
  }
}

const Object _unchanged = Object();

final superadminAdminFormControllerProvider =
    StateNotifierProvider.autoDispose<SuperadminAdminFormController, SuperadminAdminFormState>(
  (ref) => SuperadminAdminFormController(ref),
);

class SuperadminAdminFormController extends StateNotifier<SuperadminAdminFormState> {
  SuperadminAdminFormController(this._ref) : super(const SuperadminAdminFormState());

  final Ref _ref;

  Future<void> loadReferenceData() async {
    if (state.isLoadingReferenceData) return;
    state = state.copyWith(isLoadingReferenceData: true, errorMessage: null, effect: null);

    final result = await _ref.read(loadSuperadminAdminFormReferenceDataUseCaseProvider).countries();
    if (!mounted) return;

    result.when(
      success: (countries) {
        final defaultCountry = _findDefaultCountry(countries);
        state = state.copyWith(
          countries: countries,
          selectedCountry: state.selectedCountry ?? defaultCountry,
          phoneCountryIsoCode: state.phoneCountryIsoCode.isEmpty ? (defaultCountry?.isoCode ?? 'IN') : state.phoneCountryIsoCode,
          isLoadingReferenceData: false,
          errorMessage: null,
        );
        final countryCode = state.selectedCountry?.isoCode;
        if (countryCode != null && countryCode.trim().isNotEmpty) {
          loadStates(countryCode);
        }
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingReferenceData: false,
          errorMessage: _message(error, fallback: "Couldn't load countries."),
          effect: SuperadminAdminFormEffect(
            message: _message(error, fallback: "Couldn't load countries."),
            isSuccess: false,
          ),
        );
      },
    );
  }

  Future<void> loadStates(String countryCode) async {
    if (countryCode.trim().isEmpty || state.isLoadingStates) return;
    state = state.copyWith(isLoadingStates: true, states: const <ReferenceOption>[], cities: const <ReferenceOption>[], selectedState: null, selectedCity: null);

    final result = await _ref.read(loadSuperadminAdminFormReferenceDataUseCaseProvider).states(countryCode);
    if (!mounted) return;

    result.when(
      success: (items) => state = state.copyWith(isLoadingStates: false, states: items, errorMessage: null),
      failure: (error) => state = state.copyWith(
        isLoadingStates: false,
        errorMessage: _message(error, fallback: "Couldn't load states."),
        effect: SuperadminAdminFormEffect(message: _message(error, fallback: "Couldn't load states."), isSuccess: false),
      ),
    );
  }

  Future<void> loadCities(String countryCode, String stateCode) async {
    if (countryCode.trim().isEmpty || stateCode.trim().isEmpty || state.isLoadingCities) return;
    state = state.copyWith(isLoadingCities: true, cities: const <ReferenceOption>[], selectedCity: null);

    final result = await _ref.read(loadSuperadminAdminFormReferenceDataUseCaseProvider).cities(countryCode, stateCode);
    if (!mounted) return;

    result.when(
      success: (items) => state = state.copyWith(isLoadingCities: false, cities: items, errorMessage: null),
      failure: (error) => state = state.copyWith(
        isLoadingCities: false,
        errorMessage: _message(error, fallback: "Couldn't load cities."),
        effect: SuperadminAdminFormEffect(message: _message(error, fallback: "Couldn't load cities."), isSuccess: false),
      ),
    );
  }

  Future<void> selectCountry(CountryOption country) async {
    state = state.copyWith(
      selectedCountry: country,
      selectedState: null,
      selectedCity: null,
      states: const <ReferenceOption>[],
      cities: const <ReferenceOption>[],
    );
    await loadStates(country.isoCode);
  }

  Future<void> selectState(ReferenceOption selectedState) async {
    final countryCode = state.selectedCountry?.isoCode ?? '';
    state = state.copyWith(
      selectedState: selectedState,
      selectedCity: null,
      cities: const <ReferenceOption>[],
    );
    await loadCities(countryCode, selectedState.value);
  }

  void selectCity(ReferenceOption city) {
    state = state.copyWith(selectedCity: city);
  }

  void selectPhoneCountry({required String isoCode, required String phoneCode}) {
    state = state.copyWith(phoneCountryIsoCode: isoCode, phoneCode: phoneCode);
  }

  Future<bool> submitCreateAdmin({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
    required String company,
    String? address,
    String? country,
    String? stateName,
    String? city,
    String? pincode,
    String? credits,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);

    final result = await _ref.read(createSuperadminAdminUseCaseProvider)(
          SuperadminAdminMutationInput(
            _cleanFields(<String, Object?>{
              'name': name,
              'email': email,
              'mobilePrefix': '+${state.phoneCode}',
              'mobileNumber': phone,
              'username': username,
              'password': password,
              'companyName': company,
              'address': address,
              'country': country ?? state.selectedCountry?.isoCode,
              'state': stateName ?? state.selectedState?.value,
              'city': city ?? state.selectedCity?.label,
              'pincode': pincode,
              'credits': credits,
            }),
          ),
        );
    if (!mounted) return false;

    return result.when(
      success: (_) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          effect: const SuperadminAdminFormEffect(message: 'Admin created', isSuccess: true),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't create admin.");
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: message,
          effect: SuperadminAdminFormEffect(message: message, isSuccess: false),
        );
        return false;
      },
    );
  }

  Future<bool> submitUpdateAdmin(
    String adminId, {
    required String name,
    required String email,
    required String phone,
    required String username,
    required String company,
    String? address,
    String? country,
    String? stateName,
    String? city,
    String? pincode,
    String? credits,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);

    final result = await _ref.read(updateSuperadminAdminUseCaseProvider)(
          adminId,
          SuperadminAdminMutationInput(
            _cleanFields(<String, Object?>{
              'name': name,
              'email': email,
              'mobilePrefix': '+${state.phoneCode}',
              'mobileNumber': phone,
              'username': username,
              'companyName': company,
              'address': address,
              'country': country ?? state.selectedCountry?.isoCode,
              'state': stateName ?? state.selectedState?.value,
              'city': city ?? state.selectedCity?.label,
              'pincode': pincode,
              'credits': credits,
            }),
          ),
        );
    if (!mounted) return false;

    return result.when(
      success: (_) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          effect: const SuperadminAdminFormEffect(message: 'Admin updated', isSuccess: true),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't update admin.");
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: message,
          effect: SuperadminAdminFormEffect(message: message, isSuccess: false),
        );
        return false;
      },
    );
  }

  Future<bool> updateCompany(Map<String, Object?> fields, {String? companyId}) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final useCase = _ref.read(updateSuperadminCompanyUseCaseProvider);
    final result = companyId != null && companyId.trim().isNotEmpty
        ? await useCase.config(companyId, SuperadminAdminMutationInput(_cleanFields(fields)))
        : await useCase(SuperadminAdminMutationInput(_cleanFields(fields)));
    if (!mounted) return false;

    return result.when(
      success: (_) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: null,
          effect: const SuperadminAdminFormEffect(message: 'Company updated', isSuccess: true),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't update company.");
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: message,
          effect: SuperadminAdminFormEffect(message: message, isSuccess: false),
        );
        return false;
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  CountryOption? _findDefaultCountry(List<CountryOption> countries) {
    if (countries.isEmpty) return null;
    for (final country in countries) {
      if (country.isoCode.toUpperCase() == 'IN') return country;
    }
    return countries.first;
  }

  Map<String, Object?> _cleanFields(Map<String, Object?> fields) {
    final cleaned = <String, Object?>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      cleaned[entry.key] = value;
    }
    return cleaned;
  }

  String _message(Object error, {required String fallback}) {
    return error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
  }
}
