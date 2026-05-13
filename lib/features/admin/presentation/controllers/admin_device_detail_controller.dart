import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_device_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';

class AdminDeviceDetailState {
  const AdminDeviceDetailState({this.detail, this.isLoading = false, this.errorMessage});
  final AdminDeviceListItem? detail;
  final bool isLoading;
  final String? errorMessage;

  AdminDeviceDetailState copyWith({AdminDeviceListItem? detail, bool? isLoading, Object? errorMessage = _unchanged}) {
    return AdminDeviceDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final adminDeviceDetailControllerProvider = StateNotifierProvider.autoDispose.family<AdminDeviceDetailController, AdminDeviceDetailState, String>((ref, deviceId) {
  final controller = AdminDeviceDetailController(ref, deviceId);
  controller.load();
  return controller;
});

class AdminDeviceDetailController extends StateNotifier<AdminDeviceDetailState> {
  AdminDeviceDetailController(this._ref, this._deviceId) : super(const AdminDeviceDetailState());
  final Ref _ref;
  final String _deviceId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getAdminDeviceDetailUseCaseProvider)(_deviceId);
    if (!mounted) return;
    result.when(
      success: (item) => state = state.copyWith(detail: item, isLoading: false),
      failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load device.")),
    );
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
