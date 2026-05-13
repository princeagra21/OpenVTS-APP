import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

class AdminDriverDetailEffect {
  const AdminDriverDetailEffect.success(this.message) : isError = false;
  const AdminDriverDetailEffect.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

class AdminDriverDetailState {
  const AdminDriverDetailState({
    this.detail,
    this.documents = const <AdminDocumentItem>[],
    this.linkedUsers = const <AdminUserListItem>[],
    this.unlinkedUsers = const <AdminUserListItem>[],
    this.isLoadingDetail = false,
    this.isLoadingDocuments = false,
    this.isLoadingUsers = false,
    this.isSaving = false,
    this.errorMessage,
    this.effect,
  });

  final AdminDriverDetails? detail;
  final List<AdminDocumentItem> documents;
  final List<AdminUserListItem> linkedUsers;
  final List<AdminUserListItem> unlinkedUsers;
  final bool isLoadingDetail;
  final bool isLoadingDocuments;
  final bool isLoadingUsers;
  final bool isSaving;
  final String? errorMessage;
  final AdminDriverDetailEffect? effect;

  AdminDriverDetailState copyWith({
    AdminDriverDetails? detail,
    List<AdminDocumentItem>? documents,
    List<AdminUserListItem>? linkedUsers,
    List<AdminUserListItem>? unlinkedUsers,
    bool? isLoadingDetail,
    bool? isLoadingDocuments,
    bool? isLoadingUsers,
    bool? isSaving,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return AdminDriverDetailState(
      detail: detail ?? this.detail,
      documents: documents ?? this.documents,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      unlinkedUsers: unlinkedUsers ?? this.unlinkedUsers,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as AdminDriverDetailEffect?,
    );
  }
}

const Object _unchanged = Object();

final adminDriverDetailControllerProvider = StateNotifierProvider.autoDispose.family<AdminDriverDetailController, AdminDriverDetailState, String>((ref, driverId) {
  final controller = AdminDriverDetailController(ref, driverId);
  controller.loadDetail();
  return controller;
});

class AdminDriverDetailController extends StateNotifier<AdminDriverDetailState> {
  AdminDriverDetailController(this._ref, this._driverId) : super(const AdminDriverDetailState());
  final Ref _ref;
  final String _driverId;

  Future<void> loadDetail() async {
    state = state.copyWith(isLoadingDetail: true, errorMessage: null, effect: null);
    final result = await _ref.read(getAdminDriverDetailUseCaseProvider)(_driverId);
    if (!mounted) return;
    result.when(
      success: (detail) => state = state.copyWith(detail: detail, isLoadingDetail: false),
      failure: (error) { final message = _message(error, fallback: "Couldn't load driver details."); state = state.copyWith(isLoadingDetail: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message)); },
    );
  }

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoadingDocuments: true, errorMessage: null, effect: null);
    final result = await _ref.read(getAdminDriverDocumentsUseCaseProvider)(_driverId);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(documents: items, isLoadingDocuments: false),
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load driver documents.");
        state = state.copyWith(isLoadingDocuments: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message));
      },
    );
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true, errorMessage: null, effect: null);
    final linked = await _ref.read(getAdminDriverLinkedUsersUseCaseProvider)(_driverId);
    final unlinked = await _ref.read(getAdminDriverUnlinkedUsersUseCaseProvider)(_driverId);
    if (!mounted) return;
    final linkedError = linked.errorOrNull;
    final unlinkedError = unlinked.errorOrNull;
    if (linkedError != null || unlinkedError != null) {
      final message = _message(linkedError ?? unlinkedError!, fallback: "Couldn't load linked users.");
      state = state.copyWith(isLoadingUsers: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message));
      return;
    }
    state = state.copyWith(
      linkedUsers: linked.valueOrNull ?? const <AdminUserListItem>[],
      unlinkedUsers: unlinked.valueOrNull ?? const <AdminUserListItem>[],
      isLoadingUsers: false,
    );
  }

  Future<bool> updateStatus(bool isActive) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateAdminDriverUseCaseProvider)(_driverId, isActive);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, effect: const AdminDriverDetailEffect.success('Driver status updated.'));
        loadDetail();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't update driver status.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> assignUser(int userId) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(assignAdminDriverUserUseCaseProvider)(_driverId, userId: userId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, effect: const AdminDriverDetailEffect.success('User assigned.'));
        loadUsers();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't assign user.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> unassignUser(int userId) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(unassignAdminDriverUserUseCaseProvider)(_driverId, userId: userId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, effect: const AdminDriverDetailEffect.success('User removed.'));
        loadUsers();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't remove user.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminDriverDetailEffect.error(message));
        return false;
      },
    );
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
