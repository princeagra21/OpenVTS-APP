import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_dashboard.dart';

part 'superadmin_dashboard_state.freezed.dart';

@freezed
abstract class SuperadminDashboardState with _$SuperadminDashboardState {
  const factory SuperadminDashboardState.initial() = _Initial;
  const factory SuperadminDashboardState.loading() = _Loading;
  const factory SuperadminDashboardState.loaded({required SuperadminDashboard dashboard}) = _Loaded;
  const factory SuperadminDashboardState.error(AppError error) = _Error;
}
