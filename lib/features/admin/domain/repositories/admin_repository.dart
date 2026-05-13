import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_dashboard.dart';

/// Domain boundary for Admin feature use cases.
abstract interface class AdminRepository {
  Future<Result<AdminDashboard, AppError>> getDashboard();

  Future<Result<Object?, AppError>> loadResource(String resourceKey);
}
