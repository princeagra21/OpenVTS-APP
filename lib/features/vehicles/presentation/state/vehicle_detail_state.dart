import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';

part 'vehicle_detail_state.freezed.dart';

@freezed
abstract class VehicleDetailState with _$VehicleDetailState {
  const factory VehicleDetailState.initial() = _Initial;
  const factory VehicleDetailState.loading() = _Loading;
  const factory VehicleDetailState.loaded(Vehicle vehicle) = _Loaded;
  const factory VehicleDetailState.error(AppError error) = _Error;
}
