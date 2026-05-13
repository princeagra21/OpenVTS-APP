import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_vehicle_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';

class SuperadminVehicleListState {
  const SuperadminVehicleListState({this.items = const <SuperadminVehicleListItem>[], this.isLoading = false, this.errorMessage});
  final List<SuperadminVehicleListItem> items;
  final bool isLoading;
  final String? errorMessage;
  SuperadminVehicleListState copyWith({List<SuperadminVehicleListItem>? items, bool? isLoading, Object? errorMessage = _unchanged}) => SuperadminVehicleListState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
  );
}
const Object _unchanged = Object();
final superadminVehicleListControllerProvider = StateNotifierProvider.autoDispose<SuperadminVehicleListController, SuperadminVehicleListState>((ref) => SuperadminVehicleListController(ref));
class SuperadminVehicleListController extends StateNotifier<SuperadminVehicleListState> {
  SuperadminVehicleListController(this._ref) : super(const SuperadminVehicleListState());
  final Ref _ref;
  Future<void> loadVehicles({String? adminId, int page = 1, int limit = 100}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getSuperadminVehiclesUseCaseProvider)(adminId: adminId, page: page, limit: limit);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false, errorMessage: null),
      failure: (error) => state = state.copyWith(items: const <SuperadminVehicleListItem>[], isLoading: false, errorMessage: _message(error, fallback: "Couldn't load vehicles.")),
    );
  }
  String _message(Object error, {required String fallback}) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
