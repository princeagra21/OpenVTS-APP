import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/domain/entities/user_dashboard.dart';

part 'user_dashboard_state.freezed.dart';

@freezed
abstract class UserDashboardState with _$UserDashboardState {
  const factory UserDashboardState.initial() = _Initial;
  const factory UserDashboardState.loading() = _Loading;
  const factory UserDashboardState.loaded({required UserDashboard dashboard}) = _Loaded;
  const factory UserDashboardState.error(AppError error) = _Error;
}
