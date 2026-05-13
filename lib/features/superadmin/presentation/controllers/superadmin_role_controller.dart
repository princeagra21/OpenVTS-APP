import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_settings_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';

class SuperadminRoleState {
  const SuperadminRoleState({this.roles = const <SuperadminRole>[], this.isLoading = false, this.isSaving = false, this.errorMessage});
  final List<SuperadminRole> roles;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  SuperadminRoleState copyWith({List<SuperadminRole>? roles, bool? isLoading, bool? isSaving, Object? errorMessage = _unchanged}) => SuperadminRoleState(
    roles: roles ?? this.roles,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
  );
}
const Object _unchanged = Object();
final superadminRoleControllerProvider = StateNotifierProvider.autoDispose<SuperadminRoleController, SuperadminRoleState>((ref) => SuperadminRoleController(ref));
class SuperadminRoleController extends StateNotifier<SuperadminRoleState> {
  SuperadminRoleController(this._ref) : super(const SuperadminRoleState());
  final Ref _ref;
  Future<void> loadRoles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getSuperadminRolesUseCaseProvider)();
    if (!mounted) return;
    result.when(success: (roles) => state = state.copyWith(roles: roles, isLoading: false, errorMessage: null), failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load roles.")));
  }
  Future<bool> updateRole(SuperadminRoleMutationInput input) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _ref.read(updateSuperadminRoleUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(success: (role) {
      final next = <SuperadminRole>[];
      var replaced = false;
      for (final item in state.roles) {
        if (item.key == role.key) { next.add(role); replaced = true; } else { next.add(item); }
      }
      if (!replaced) next.add(role);
      state = state.copyWith(roles: next, isSaving: false, errorMessage: null);
      return true;
    }, failure: (error) { state = state.copyWith(isSaving: false, errorMessage: _message(error, fallback: "Couldn't save role.")); return false; });
  }
  String _message(Object error, {required String fallback}) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
