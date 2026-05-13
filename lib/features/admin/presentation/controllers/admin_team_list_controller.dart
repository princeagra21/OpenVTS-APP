import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_team_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';

class AdminTeamListState {
  const AdminTeamListState({
    this.items = const <AdminTeamListItem>[],
    this.isLoading = false,
    this.errorMessage,
    this.updatingIds = const <String>{},
  });

  final List<AdminTeamListItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> updatingIds;

  AdminTeamListState copyWith({
    List<AdminTeamListItem>? items,
    bool? isLoading,
    Object? errorMessage = _unchanged,
    Set<String>? updatingIds,
  }) => AdminTeamListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
        updatingIds: updatingIds ?? this.updatingIds,
      );
}

const Object _unchanged = Object();

final adminTeamListControllerProvider = StateNotifierProvider.autoDispose<AdminTeamListController, AdminTeamListState>((ref) {
  return AdminTeamListController(ref);
});

class AdminTeamListController extends StateNotifier<AdminTeamListState> {
  AdminTeamListController(this._ref) : super(const AdminTeamListState());
  final Ref _ref;

  Future<void> loadTeams({String? search, int page = 1, int limit = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getAdminTeamsUseCaseProvider)(search: search, page: page, limit: limit);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false),
      failure: (error) => state = state.copyWith(items: const <AdminTeamListItem>[], isLoading: false, errorMessage: _message(error, fallback: "Couldn't load teams.")),
    );
  }

  Future<bool> updateStatus(AdminTeamListItem item, bool nextValue) async {
    final id = item.id.trim();
    if (id.isEmpty || state.updatingIds.contains(id)) return false;
    final previousItems = state.items;
    final mapper = _ref.read(adminTeamMapperProvider);
    state = state.copyWith(
      items: previousItems.map((team) => team.id == id ? mapper.withActive(team, nextValue) : team).toList(growable: false),
      updatingIds: <String>{...state.updatingIds, id},
      errorMessage: null,
    );
    final result = await _ref.read(updateAdminTeamUseCaseProvider).updateStatus(id, nextValue);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id));
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: previousItems, updatingIds: <String>{...state.updatingIds}..remove(id), errorMessage: _message(error, fallback: "Couldn't update team status."));
        return false;
      },
    );
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
