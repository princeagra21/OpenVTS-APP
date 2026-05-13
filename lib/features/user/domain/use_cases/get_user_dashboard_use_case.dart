import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_dashboard.dart';
import 'package:open_vts/features/user/domain/repositories/user_repository.dart';

class GetUserDashboardUseCase {
  const GetUserDashboardUseCase(this.repository);

  final UserRepository repository;

  Future<Result<UserDashboard, AppError>> call() => repository.getDashboard();
}
