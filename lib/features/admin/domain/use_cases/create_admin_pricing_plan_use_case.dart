import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class CreateAdminPricingPlanUseCase {
  const CreateAdminPricingPlanUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<Map<String, Object?>, AppError>> call({required String name, required int durationDays, required num price, required String currency}) {
    return _repository.createPricingPlan(name: name, durationDays: durationDays, price: price, currency: currency);
  }
}
