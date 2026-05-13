import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminPricingPlansUseCase {
  const GetAdminPricingPlansUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<PricingPlan>, AppError>> call() => _repository.getPricingPlans();
}
