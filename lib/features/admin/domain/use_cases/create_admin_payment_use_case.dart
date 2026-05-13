import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class CreateAdminPaymentUseCase {
  const CreateAdminPaymentUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<void, AppError>> call({required String userId, required List<String> vehicleIds, required String amount, required String paymentMode}) {
    return _repository.createPayment(userId: userId, vehicleIds: vehicleIds, amount: amount, paymentMode: paymentMode);
  }
}
