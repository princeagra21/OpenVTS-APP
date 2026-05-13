import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_dashboard.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_repository.dart';

class GetAdminDashboardUseCase {
  const GetAdminDashboardUseCase(this.repository);

  final AdminRepository repository;

  Future<Result<AdminDashboard, AppError>> call() => repository.getDashboard();
}
