import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';

part 'vehicle_list_state.freezed.dart';

@freezed
abstract class VehicleListUiState with _$VehicleListUiState {
  const factory VehicleListUiState.initial() = _Initial;
  const factory VehicleListUiState.loading() = _Loading;
  const factory VehicleListUiState.loaded({required List<Vehicle> vehicles, @Default(0) int total}) = _Loaded;
  const factory VehicleListUiState.empty() = _Empty;
  const factory VehicleListUiState.error(AppError error) = _Error;
}
