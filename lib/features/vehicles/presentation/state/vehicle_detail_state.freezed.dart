// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'vehicle_detail_state.dart';

mixin _$VehicleDetailState {}

class _Initial implements VehicleDetailState { const _Initial(); }
class _Loading implements VehicleDetailState { const _Loading(); }
class _Loaded implements VehicleDetailState { const _Loaded(this.vehicle); final Vehicle vehicle; }
class _Error implements VehicleDetailState { const _Error(this.error); final AppError error; }
