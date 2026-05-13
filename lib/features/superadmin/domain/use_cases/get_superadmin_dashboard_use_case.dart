import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_dashboard.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_repository.dart';

class GetSuperadminDashboardUseCase {
  const GetSuperadminDashboardUseCase(this.repository);

  final SuperadminRepository repository;

  Future<Result<SuperadminDashboard, AppError>> call() => repository.getDashboard();
}
