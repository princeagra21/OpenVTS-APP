import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_sub_user_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';

class UserSubUserDetailEffect {
  const UserSubUserDetailEffect(this.message, {this.isSuccess = false});
  final String message;
  final bool isSuccess;
}

class UserSubUserDetailState {
  const UserSubUserDetailState({
    this.detail,
    this.vehicles = const <Map<String, dynamic>>[],
    this.allVehicles = const <Map<String, dynamic>>[],
    this.isLoading = false,
    this.isLoadingVehicles = false,
    this.isAssigning = false,
    this.isDeleting = false,
    this.errorMessage,
    this.effect,
  });

  final UserSubUserItem? detail;
  final List<Map<String, dynamic>> vehicles;
  final List<Map<String, dynamic>> allVehicles;
  final bool isLoading;
  final bool isLoadingVehicles;
  final bool isAssigning;
  final bool isDeleting;
  final String? errorMessage;
  final UserSubUserDetailEffect? effect;

  UserSubUserDetailState copyWith({
    UserSubUserItem? detail,
    List<Map<String, dynamic>>? vehicles,
    List<Map<String, dynamic>>? allVehicles,
    bool? isLoading,
    bool? isLoadingVehicles,
    bool? isAssigning,
    bool? isDeleting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return UserSubUserDetailState(
      detail: detail ?? this.detail,
      vehicles: vehicles ?? this.vehicles,
      allVehicles: allVehicles ?? this.allVehicles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isAssigning: isAssigning ?? this.isAssigning,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as UserSubUserDetailEffect?,
    );
  }
}

const Object _unchanged = Object();

final userSubUserDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<UserSubUserDetailController, UserSubUserDetailState, String>(
  (ref, subUserId) => UserSubUserDetailController(ref, subUserId),
);

class UserSubUserDetailController extends StateNotifier<UserSubUserDetailState> {
  UserSubUserDetailController(this._ref, this._subUserId) : super(const UserSubUserDetailState());
  final Ref _ref;
  final String _subUserId;

  Future<void> load({UserSubUserItem? initial}) async {
    if (initial != null && state.detail == null) {
      state = state.copyWith(detail: initial);
    }
    await Future.wait(<Future<void>>[
      if (initial == null) loadDetails(),
      loadVehicles(),
    ]);
  }

  Future<void> loadDetails() async {
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getUserSubUserDetailUseCaseProvider)(_subUserId);
    if (!mounted) return;
    result.when(
      success: (details) => state = state.copyWith(
        detail: details,
        isLoading: false,
        errorMessage: null,
      ),
      failure: (error) => state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, "Couldn't load sub-user details."),
        effect: UserSubUserDetailEffect(_message(error, "Couldn't load sub-user details.")),
      ),
    );
  }

  Future<void> loadVehicles() async {
    state = state.copyWith(isLoadingVehicles: true, errorMessage: null);
    final result = await _ref.read(getUserSubUserVehiclesUseCaseProvider)(_subUserId);
    if (!mounted) return;
    result.when(
      success: (items) {
        final vehicles = items
            .map((item) => <String, dynamic>{for (final entry in item.entries) entry.key: entry.value})
            .toList(growable: false);
        state = state.copyWith(
          vehicles: vehicles,
          allVehicles: vehicles,
          isLoadingVehicles: false,
        );
      },
      failure: (error) => state = state.copyWith(
        isLoadingVehicles: false,
        errorMessage: _message(error, "Couldn't load sub-user vehicles."),
        effect: UserSubUserDetailEffect(_message(error, "Couldn't load sub-user vehicles.")),
      ),
    );
  }

  void loadAllVehiclesFromAssigned() {
    state = state.copyWith(allVehicles: state.vehicles);
  }

  Future<void> assignVehicles(List<String> vehicleIds) async {
    if (state.isAssigning || vehicleIds.isEmpty) return;
    state = state.copyWith(isAssigning: true, effect: null, errorMessage: null);
    for (final id in vehicleIds) {
      final vehicleId = int.tryParse(id);
      if (vehicleId == null) continue;
      final result = await _ref.read(assignUserSubUserVehicleUseCaseProvider)(_subUserId, <int>[vehicleId]);
      if (!mounted) return;
      final failed = result.when(success: (_) => false, failure: (error) {
        final message = _message(error, 'Failed to assign vehicle.');
        state = state.copyWith(errorMessage: message, effect: UserSubUserDetailEffect(message));
        return true;
      });
      if (failed) break;
    }
    await loadVehicles();
    if (!mounted) return;
    state = state.copyWith(isAssigning: false);
  }

  Future<void> unassignVehicle(String id) async {
    if (state.isAssigning || id.isEmpty) return;
    final vehicleId = int.tryParse(id);
    if (vehicleId == null) return;
    state = state.copyWith(isAssigning: true, effect: null, errorMessage: null);
    final result = await _ref.read(unassignUserSubUserVehicleUseCaseProvider)(_subUserId, <int>[vehicleId]);
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (error) {
        final message = _message(error, 'Failed to unassign vehicle.');
        state = state.copyWith(errorMessage: message, effect: UserSubUserDetailEffect(message));
      },
    );
    await loadVehicles();
    if (!mounted) return;
    state = state.copyWith(isAssigning: false);
  }

  Future<void> deleteSubUser() async {
    if (state.isDeleting) return;
    state = state.copyWith(isDeleting: true, effect: null, errorMessage: null);
    final result = await _ref.read(deleteUserSubUserUseCaseProvider)(_subUserId);
    if (!mounted) return;
    result.when(
      success: (_) => state = state.copyWith(
        isDeleting: false,
        effect: const UserSubUserDetailEffect('Sub-user deleted', isSuccess: true),
      ),
      failure: (error) {
        final message = _message(error, 'Failed to delete sub-user.');
        state = state.copyWith(isDeleting: false, errorMessage: message, effect: UserSubUserDetailEffect(message));
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  String _message(Object error, String fallback) =>
      error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
