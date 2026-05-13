import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_vehicle_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';

class SuperadminVehicleDetailState {
  const SuperadminVehicleDetailState({this.detail, this.isLoading = false, this.errorMessage});
  final SuperadminVehicleDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  SuperadminVehicleDetailState copyWith({SuperadminVehicleDetail? detail, bool? isLoading, Object? errorMessage = _unchanged}) => SuperadminVehicleDetailState(
    detail: detail ?? this.detail,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
  );
}
const Object _unchanged = Object();
final superadminVehicleDetailControllerProvider = StateNotifierProvider.autoDispose.family<SuperadminVehicleDetailController, SuperadminVehicleDetailState, String>((ref, vehicleId) => SuperadminVehicleDetailController(ref, vehicleId));
class SuperadminVehicleDetailController extends StateNotifier<SuperadminVehicleDetailState> {
  SuperadminVehicleDetailController(this._ref, this._vehicleId) : super(const SuperadminVehicleDetailState());
  final Ref _ref;
  final String _vehicleId;
  bool _loadInFlight = false;

  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ref.read(getSuperadminVehicleDetailUseCaseProvider)(_vehicleId);
      if (!mounted) return;
      result.when(
        success: (detail) => state = state.copyWith(detail: detail, isLoading: false, errorMessage: null),
        failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load vehicle details.")),
      );
    } finally {
      _loadInFlight = false;
    }
  }
  String _message(Object error, {required String fallback}) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
