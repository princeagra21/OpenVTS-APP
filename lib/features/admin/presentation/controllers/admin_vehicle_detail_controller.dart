import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_vehicle_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';

class AdminVehicleDetailEffect {
  const AdminVehicleDetailEffect.success(this.message) : isError = false;
  const AdminVehicleDetailEffect.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

class AdminVehicleDetailState {
  const AdminVehicleDetailState({
    this.vehicle,
    this.documents = const <AdminDocumentItem>[],
    this.assignedDriver,
    this.users = const <AdminUserListItem>[],
    this.logs = const <AdminVehicleLogItem>[],
    this.isLoading = false,
    this.isLoadingUsers = false,
    this.isLoadingDocuments = false,
    this.isLoadingLogs = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
    this.effect,
  });

  final AdminVehicleDetails? vehicle;
  final List<AdminDocumentItem> documents;
  final String? assignedDriver;
  final List<AdminUserListItem> users;
  final List<AdminVehicleLogItem> logs;
  final bool isLoading;
  final bool isLoadingUsers;
  final bool isLoadingDocuments;
  final bool isLoadingLogs;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;
  final AdminVehicleDetailEffect? effect;

  AdminVehicleDetailState copyWith({
    AdminVehicleDetails? vehicle,
    List<AdminDocumentItem>? documents,
    Object? assignedDriver = _unchanged,
    List<AdminUserListItem>? users,
    List<AdminVehicleLogItem>? logs,
    bool? isLoading,
    bool? isLoadingUsers,
    bool? isLoadingDocuments,
    bool? isLoadingLogs,
    bool? isSaving,
    bool? isDeleting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return AdminVehicleDetailState(
      vehicle: vehicle ?? this.vehicle,
      documents: documents ?? this.documents,
      assignedDriver: identical(assignedDriver, _unchanged) ? this.assignedDriver : assignedDriver as String?,
      users: users ?? this.users,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as AdminVehicleDetailEffect?,
    );
  }
}

const Object _unchanged = Object();

final adminVehicleDetailControllerProvider = StateNotifierProvider.autoDispose.family<AdminVehicleDetailController, AdminVehicleDetailState, String>((ref, vehicleId) {
  final controller = AdminVehicleDetailController(ref, vehicleId);
  controller.loadVehicle(vehicleId);
  return controller;
});

class AdminVehicleDetailController extends StateNotifier<AdminVehicleDetailState> {
  AdminVehicleDetailController(this._ref, this._vehicleId) : super(const AdminVehicleDetailState());

  final Ref _ref;
  String _vehicleId;

  Future<void> loadVehicle(String id) async {
    _vehicleId = id;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getAdminVehicleDetailUseCaseProvider)(id);
    if (!mounted) return;
    result.when(
      success: (vehicle) {
        state = state.copyWith(
          vehicle: vehicle,
          assignedDriver: vehicle.primaryUser,
          isLoading: false,
        );
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load vehicle details.");
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
          effect: AdminVehicleDetailEffect.error(message),
        );
      },
    );
  }

  Future<void> refresh() => loadVehicle(_vehicleId);

  Future<void> loadLinkedUsers() async {
    state = state.copyWith(isLoadingUsers: true, errorMessage: null, effect: null);
    final result = await _ref.read(getAdminVehicleLinkedUsersUseCaseProvider)(_vehicleId);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(users: items, isLoadingUsers: false),
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load linked users.");
        state = state.copyWith(
          users: const <AdminUserListItem>[],
          isLoadingUsers: false,
          errorMessage: message,
          effect: AdminVehicleDetailEffect.error(message),
        );
      },
    );
  }

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoadingDocuments: true, errorMessage: null, effect: null);
    final result = await _ref.read(getAdminVehicleDocumentsUseCaseProvider)(_vehicleId);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(documents: items, isLoadingDocuments: false),
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load vehicle documents.");
        state = state.copyWith(
          documents: const <AdminDocumentItem>[],
          isLoadingDocuments: false,
          errorMessage: message,
          effect: AdminVehicleDetailEffect.error(message),
        );
      },
    );
  }

  Future<void> loadLogs({DateTime? from, DateTime? to, int limit = 50}) async {
    final imei = _safe(state.vehicle?.imei);
    if (imei.isEmpty) return;
    state = state.copyWith(isLoadingLogs: true, errorMessage: null, effect: null);
    final now = DateTime.now();
    final start = from ?? DateTime(now.year - 1, 1, 1);
    final end = to ?? now;
    final query = <String, Object?>{
      'from': DateFormat('yyyy-MM-dd').format(start),
      'to': DateFormat('yyyy-MM-dd').format(end),
      'limit': limit,
    };
    final result = await _ref.read(getAdminVehicleLogsUseCaseProvider)(imei, query: query);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(logs: items, isLoadingLogs: false),
      failure: (error) {
        final message = _message(error, fallback: "Couldn't load vehicle logs.");
        state = state.copyWith(
          logs: const <AdminVehicleLogItem>[],
          isLoadingLogs: false,
          errorMessage: message,
          effect: AdminVehicleDetailEffect.error(message),
        );
      },
    );
  }

  Future<bool> updateConfig(VehicleConfigUpdate payload) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateAdminVehicleConfigUseCaseProvider)(_vehicleId, payload);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, effect: const AdminVehicleDetailEffect.success('Saved'));
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't save config.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminVehicleDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> assignDriver(String driverId) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(assignAdminVehicleDriverUseCaseProvider)(_vehicleId, driverId: driverId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, assignedDriver: driverId, effect: const AdminVehicleDetailEffect.success('Driver assigned.'));
        refresh();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't assign driver.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminVehicleDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> unassignDriver() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(unassignAdminVehicleDriverUseCaseProvider)(_vehicleId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, assignedDriver: null, effect: const AdminVehicleDetailEffect.success('Driver removed.'));
        refresh();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't remove driver.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminVehicleDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> deleteVehicle() async {
    if (state.isDeleting) return false;
    state = state.copyWith(isDeleting: true, errorMessage: null, effect: null);
    final result = await _ref.read(deleteAdminVehicleUseCaseProvider)(_vehicleId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isDeleting: false, effect: const AdminVehicleDetailEffect.success('Vehicle deleted.'));
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't delete vehicle.");
        state = state.copyWith(isDeleting: false, errorMessage: message, effect: AdminVehicleDetailEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> updateStatus(bool isActive) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateAdminVehicleStatusUseCaseProvider)(_vehicleId, isActive);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSaving: false, effect: const AdminVehicleDetailEffect.success('Vehicle status updated.'));
        refresh();
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't update vehicle status.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: AdminVehicleDetailEffect.error(message));
        return false;
      },
    );
  }

  void clearEffect() {
    if (state.effect == null) return;
    state = state.copyWith(effect: null);
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }

  String _message(Object error, {required String fallback}) {
    if (error is AppError && error.message.trim().isNotEmpty) return error.message;
    final text = error.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null' || trimmed == '—') return '';
    return trimmed;
  }
}
