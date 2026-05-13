import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_device_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';

class AdminDeviceListState {
  const AdminDeviceListState({
    this.items = const <AdminDeviceListItem>[],
    this.isLoading = false,
    this.errorMessage,
    this.updatingIds = const <String>{},
  });

  final List<AdminDeviceListItem> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> updatingIds;

  AdminDeviceListState copyWith({
    List<AdminDeviceListItem>? items,
    bool? isLoading,
    Object? errorMessage = _unchanged,
    Set<String>? updatingIds,
  }) => AdminDeviceListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
        updatingIds: updatingIds ?? this.updatingIds,
      );
}

const Object _unchanged = Object();

final adminDeviceListControllerProvider = StateNotifierProvider.autoDispose<AdminDeviceListController, AdminDeviceListState>((ref) {
  return AdminDeviceListController(ref);
});

class AdminDeviceListController extends StateNotifier<AdminDeviceListState> {
  AdminDeviceListController(this._ref) : super(const AdminDeviceListState());
  final Ref _ref;

  Future<void> loadDevices({String? search, String? status, int page = 1, int limit = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getAdminDevicesUseCaseProvider)(search: search, status: status, page: page, limit: limit);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false),
      failure: (error) => state = state.copyWith(items: const <AdminDeviceListItem>[], isLoading: false, errorMessage: _message(error, fallback: "Couldn't load devices.")),
    );
  }

  Future<bool> updateStatus(AdminDeviceListItem item, bool nextValue) async {
    final id = item.id.trim();
    if (id.isEmpty || state.updatingIds.contains(id)) return false;
    final previousItems = state.items;
    final mapper = _ref.read(adminDeviceMapperProvider);
    state = state.copyWith(
      items: previousItems.map((device) => device.id == id ? mapper.withActive(device, nextValue) : device).toList(growable: false),
      updatingIds: <String>{...state.updatingIds, id},
      errorMessage: null,
    );
    final result = await _ref.read(adminDeviceRepositoryProvider).updateDeviceStatus(id, nextValue);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(updatingIds: <String>{...state.updatingIds}..remove(id));
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: previousItems, updatingIds: <String>{...state.updatingIds}..remove(id), errorMessage: _message(error, fallback: "Couldn't update device status."));
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
