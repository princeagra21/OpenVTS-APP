import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_workflow_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

class AddDriverFormState {
  const AddDriverFormState({
    this.countries = const [],
    this.prefixes = const [],
    this.states = const [],
    this.cities = const [],
    this.users = const [],
    this.isLoadingCountries = false,
    this.isLoadingPrefixes = false,
    this.isLoadingStates = false,
    this.isLoadingCities = false,
    this.isLoadingUsers = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<CountryOption> countries;
  final List<MobilePrefixOption> prefixes;
  final List<ReferenceOption> states;
  final List<ReferenceOption> cities;
  final List<AdminUserListItem> users;
  final bool isLoadingCountries;
  final bool isLoadingPrefixes;
  final bool isLoadingStates;
  final bool isLoadingCities;
  final bool isLoadingUsers;
  final bool isSubmitting;
  final String? errorMessage;

  AddDriverFormState copyWith({
    List<CountryOption>? countries,
    List<MobilePrefixOption>? prefixes,
    List<ReferenceOption>? states,
    List<ReferenceOption>? cities,
    List<AdminUserListItem>? users,
    bool? isLoadingCountries,
    bool? isLoadingPrefixes,
    bool? isLoadingStates,
    bool? isLoadingCities,
    bool? isLoadingUsers,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
  }) {
    return AddDriverFormState(
      countries: countries ?? this.countries,
      prefixes: prefixes ?? this.prefixes,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      users: users ?? this.users,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingPrefixes: isLoadingPrefixes ?? this.isLoadingPrefixes,
      isLoadingStates: isLoadingStates ?? this.isLoadingStates,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final addDriverControllerProvider = StateNotifierProvider.autoDispose<AddDriverController, AddDriverFormState>((ref) {
  final controller = AddDriverController(ref);
  controller.loadInitialData();
  return controller;
});

class AddDriverController extends StateNotifier<AddDriverFormState> {
  AddDriverController(this._ref) : super(const AddDriverFormState());

  final Ref _ref;

  Future<void> loadInitialData() async {
    await Future.wait([loadCountries(), loadPrefixes(), loadUsers()]);
  }

  Future<void> loadCountries() async {
    state = state.copyWith(isLoadingCountries: true, errorMessage: null);
    final result = await _ref.read(getCountriesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(countries: items, isLoadingCountries: false),
      failure: (error) => state = state.copyWith(isLoadingCountries: false, errorMessage: _message(error)),
    );
  }

  Future<void> loadPrefixes() async {
    state = state.copyWith(isLoadingPrefixes: true, errorMessage: null);
    final result = await _ref.read(getMobilePrefixesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(prefixes: items, isLoadingPrefixes: false),
      failure: (error) => state = state.copyWith(isLoadingPrefixes: false, errorMessage: _message(error)),
    );
  }

  Future<void> loadStates(String countryCode) async {
    state = state.copyWith(isLoadingStates: true, states: const [], cities: const [], errorMessage: null);
    final result = await _ref.read(getStatesUseCaseProvider)(countryCode);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(states: items, isLoadingStates: false),
      failure: (error) => state = state.copyWith(isLoadingStates: false, errorMessage: _message(error)),
    );
  }

  Future<void> loadCities(String countryCode, String stateCode) async {
    state = state.copyWith(isLoadingCities: true, cities: const [], errorMessage: null);
    final result = await _ref.read(getCitiesUseCaseProvider)(countryCode, stateCode);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(cities: items, isLoadingCities: false),
      failure: (error) => state = state.copyWith(isLoadingCities: false, errorMessage: _message(error)),
    );
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true, errorMessage: null);
    final result = await _ref.read(getAdminDriverUsersUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(users: items, isLoadingUsers: false),
      failure: (error) => state = state.copyWith(isLoadingUsers: false, errorMessage: _message(error)),
    );
  }

  Future<bool> submit(CreateAdminDriverInput input) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref.read(createAdminDriverUseCaseProvider)(input);
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
