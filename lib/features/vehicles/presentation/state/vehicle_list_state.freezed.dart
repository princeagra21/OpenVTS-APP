// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'vehicle_list_state.dart';

mixin _$VehicleListUiState {}

class _Initial implements VehicleListUiState { const _Initial(); }
class _Loading implements VehicleListUiState { const _Loading(); }
class _Loaded implements VehicleListUiState {
  const _Loaded({required this.vehicles, this.total = 0});
  final List<Vehicle> vehicles;
  final int total;
}
class _Empty implements VehicleListUiState { const _Empty(); }
class _Error implements VehicleListUiState { const _Error(this.error); final AppError error; }
