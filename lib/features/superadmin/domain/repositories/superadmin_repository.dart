import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_dashboard.dart';

/// Domain boundary for Superadmin feature use cases.
abstract interface class SuperadminRepository {
  Future<Result<SuperadminDashboard, AppError>> getDashboard();

  Future<Result<Object?, AppError>> loadResource(String resourceKey);
}
