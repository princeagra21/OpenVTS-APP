import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/domain/entities/admin_dashboard.dart';

part 'admin_dashboard_state.freezed.dart';

@freezed
abstract class AdminDashboardState with _$AdminDashboardState {
  const factory AdminDashboardState.initial() = _Initial;
  const factory AdminDashboardState.loading() = _Loading;
  const factory AdminDashboardState.loaded({required AdminDashboard dashboard}) = _Loaded;
  const factory AdminDashboardState.error(AppError error) = _Error;
}
