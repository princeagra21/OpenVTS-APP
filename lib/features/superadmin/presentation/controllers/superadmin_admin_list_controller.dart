import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_admin_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';

class SuperadminAdminListState {
  const SuperadminAdminListState({
    this.items = const <SuperadminAdminListItem>[],
    this.isLoading = false,
    this.errorMessage,
    this.updatingIds = const <String>{},
    this.impersonatingIds = const <String>{},
  });

  final List<SuperadminAdminListItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> updatingIds;
  final Set<String> impersonatingIds;

  SuperadminAdminListState copyWith({
    List<SuperadminAdminListItem>? items,
    bool? isLoading,
    Object? errorMessage = _unchanged,
    Set<String>? updatingIds,
    Set<String>? impersonatingIds,
  }) {
    return SuperadminAdminListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      updatingIds: updatingIds ?? this.updatingIds,
      impersonatingIds: impersonatingIds ?? this.impersonatingIds,
    );
  }
}

const Object _unchanged = Object();

final superadminAdminListControllerProvider = StateNotifierProvider.autoDispose<SuperadminAdminListController, SuperadminAdminListState>((ref) {
  return SuperadminAdminListController(ref);
});

class SuperadminAdminListController extends StateNotifier<SuperadminAdminListState> {
  SuperadminAdminListController(this._ref) : super(const SuperadminAdminListState());
  final Ref _ref;

  Future<void> loadAdmins({int page = 1, int limit = 50, String? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getSuperadminAdminsUseCaseProvider)(page: page, limit: limit, status: status);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false, errorMessage: null),
      failure: (error) => state = state.copyWith(items: const <SuperadminAdminListItem>[], isLoading: false, errorMessage: _message(error, fallback: "Couldn't load admins.")),
    );
  }

  Future<bool> updateStatus(SuperadminAdminListItem admin, bool isActive) async {
    final id = admin.id.trim();
    if (id.isEmpty || state.updatingIds.contains(id)) return false;
    final previous = admin.isActive;
    admin.isActive = isActive;
    state = state.copyWith(updatingIds: <String>{...state.updatingIds, id}, errorMessage: null);
    final result = await _ref.read(updateSuperadminAdminUseCaseProvider).status(id, isActive);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id), errorMessage: null);
        return true;
      },
      failure: (error) {
        admin.isActive = previous;
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id), errorMessage: _message(error, fallback: "Couldn't update status."));
        return false;
      },
    );
  }

  Future<String?> loginAsAdmin(String adminId) async {
    if (adminId.trim().isEmpty || state.impersonatingIds.contains(adminId)) return null;
    state = state.copyWith(impersonatingIds: <String>{...state.impersonatingIds, adminId}, errorMessage: null);
    final result = await _ref.read(loginAsSuperadminAdminUseCaseProvider)(adminId);
    if (!mounted) return null;
    return result.when(
      success: (token) {
        state = state.copyWith(impersonatingIds: <String>{...state.impersonatingIds}..remove(adminId), errorMessage: null);
        return token;
      },
      failure: (error) {
        state = state.copyWith(impersonatingIds: <String>{...state.impersonatingIds}..remove(adminId), errorMessage: _message(error, fallback: 'Login failed.'));
        return null;
      },
    );
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
