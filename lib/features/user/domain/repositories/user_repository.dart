import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_dashboard.dart';

/// Domain boundary for User feature use cases.
abstract interface class UserRepository {
  Future<Result<UserDashboard, AppError>> getDashboard();

  Future<Result<Object?, AppError>> loadResource(String resourceKey);
}
